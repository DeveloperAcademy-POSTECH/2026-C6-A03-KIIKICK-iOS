//
//  WorkoutManager.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/27/26.
//
//  HealthKit 세션은 경기 전체에 걸쳐 한 번만 열고 닫는다(startMatch/finishMatch).
//  위치 수집만 쿼터 단위로 멈췄다 재개한다(beginQuarter/endQuarter) — 인터벌 동안은
//  위치를 모으지 않는다.
//
//  쿼터 하나 = WorkoutPayload 하나. calories/distance는 HealthKit 누적값이라, 쿼터
//  시작 시점의 누적값을 스냅샷해뒀다가 종료 시점과의 차이로 "이번 쿼터 동안"을 구한다.
//

import HealthKit
import CoreLocation
import Foundation

@Observable
final class WorkoutManager: NSObject {

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private let locationManager = CLLocationManager()

    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var distance: Double = 0
    var speed: Double = 0

    /// 지금 쿼터가 실제로 기록 중인지(위치 수집 on/off). 인터벌 동안은 false.
    private(set) var isRecordingQuarter: Bool = false

    /// 현재 쿼터가 시작된 시각. `PlayingView`에서 라이브 타이머(`Text(_:style:.timer)`)를
    /// 그리는 데 쓴다.
    private(set) var currentQuarterStartDate: Date?
    private(set) var currentQuarterPoints: [TrackPoint] = []
    private(set) var currentQuarterHeartRateSamples: [HeartRateSample] = []
    private(set) var currentQuarterEvents: [MatchEvent] = []
    private var currentQuarterStartActiveEnergy: Double = 0
    private var currentQuarterStartDistance: Double = 0
    /// 골/어시스트를 기록한 순간 위치로 쓸, 가장 최근에 받은 위치.
    private var lastLocation: CLLocation?

    /// 경기 전체 시작 — 매치당 한 번만 호출. HealthKit 워크아웃 세션을 연다.
    func startMatch() async {
        await requestAuthorization()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.requestWhenInUseAuthorization()

        let config = HKWorkoutConfiguration()
        config.activityType = .soccer
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder
            routeBuilder = builder.seriesBuilder(for: HKSeriesType.workoutRoute()) as? HKWorkoutRouteBuilder

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
        } catch {
            print("[WorkoutManager] 세션 시작 실패 - \(error)")
        }
    }

    /// 쿼터 시작/재개 — 이번 쿼터용 버퍼를 비우고 위치 수집을 다시 켠다.
    func beginQuarter() {
        currentQuarterPoints = []
        currentQuarterHeartRateSamples = []
        currentQuarterEvents = []
        currentQuarterStartDate = Date()
        currentQuarterStartActiveEnergy = activeEnergy
        currentQuarterStartDistance = distance
        locationManager.startUpdatingLocation()
        isRecordingQuarter = true
    }

    /// 골/어시스트 스테퍼를 +1 했을 때 그 순간의 위치를 이벤트로 기록한다. 아직 위치를
    /// 한 번도 못 받았으면(GPS 픽스 전) 조용히 무시한다.
    func recordEvent(type: MatchEventType) {
        guard let lastLocation else { return }
        currentQuarterEvents.append(MatchEvent(type: type, location: TrackPoint(location: lastLocation)))
    }

    /// 스테퍼를 -1 했을 때(잘못 눌러서 되돌리는 경우) 같은 타입의 가장 최근 이벤트를 지운다.
    func removeLastEvent(type: MatchEventType) {
        if let index = currentQuarterEvents.lastIndex(where: { $0.type == type }) {
            currentQuarterEvents.remove(at: index)
        }
    }

    /// 쿼터 종료 — 위치 수집을 멈추고, 이번 쿼터 하나를 그대로 나타내는 `QuarterRecord`(로컬
    /// 저장용)와 `WorkoutPayload`(전송용)를 같이 돌려준다. 쿼터 하나 = WorkoutPayload 하나.
    /// `position`이 nil이면 PositionView를 거치지 않고 강제로 끝난 쿼터라는 뜻이다
    /// (MainView.handleForceEnd 참고).
    func endQuarter(
        quarterNumber: Int,
        position: Position?,
        goalCount: Int,
        assistCount: Int
    ) -> (record: QuarterRecord, payload: WorkoutPayload) {
        locationManager.stopUpdatingLocation()
        isRecordingQuarter = false

        let endDate = Date()
        let startDate = currentQuarterStartDate ?? endDate
        let quarterCalories = max(0, activeEnergy - currentQuarterStartActiveEnergy)
        let quarterDistance = max(0, distance - currentQuarterStartDistance)

        let record = QuarterRecord(
            quarterNumber: quarterNumber,
            position: position,
            startDate: startDate,
            endDate: endDate,
            points: currentQuarterPoints,
            heartRateSamples: currentQuarterHeartRateSamples,
            goalCount: goalCount,
            assistCount: assistCount,
            events: currentQuarterEvents
        )

        let payload = WorkoutPayload(
            startDate: startDate,
            endDate: endDate,
            points: currentQuarterPoints,
            heartRateSamples: currentQuarterHeartRateSamples,
            totalCalories: quarterCalories,
            totalDistance: quarterDistance,
            events: currentQuarterEvents,
            position: position
        )

        return (record, payload)
    }

    /// 경기 전체 종료 — HealthKit 세션을 끝낸다. 쿼터별로 이미 각자 전송했기 때문에
    /// 여기서 따로 보낼 payload는 없다.
    func finishMatch() async {
        locationManager.stopUpdatingLocation()
        isRecordingQuarter = false

        guard let session = workoutSession, let builder = workoutBuilder else { return }
        let endDate = Date()
        session.stopActivity(with: endDate)
        session.end()
        do {
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
        } catch {
            print("[WorkoutManager] 세션 종료 실패 - \(error)")
        }
    }

    // MARK: - Private Helpers

    private func requestAuthorization() async {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.runningSpeed),
        ]
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.runningSpeed),
        ]
        try? await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("[WorkoutManager] session 오류: \(error)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                guard let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: unit) else { break }
                let sample = HeartRateSample(timestamp: Date(), bpm: value)
                DispatchQueue.main.async {
                    self.heartRate = value
                    self.currentQuarterHeartRateSamples.append(sample)
                }
            case HKQuantityType(.activeEnergyBurned):
                let value = workoutBuilder.statistics(for: quantityType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async { self.activeEnergy = value }
            case HKQuantityType(.distanceWalkingRunning):
                let value = workoutBuilder.statistics(for: quantityType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                DispatchQueue.main.async { self.distance = value }
            case HKQuantityType(.runningSpeed):
                let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: .meter().unitDivided(by: .second())) ?? 0
                DispatchQueue.main.async { self.speed = value }
            default:
                break
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension WorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let point = TrackPoint(location: location)
        DispatchQueue.main.async {
            self.currentQuarterPoints.append(point)
            self.lastLocation = location
        }
        routeBuilder?.insertRouteData(locations) { success, error in
            if !success {
                print("[WorkoutManager] 경로 데이터 저장 실패 - \(error?.localizedDescription ?? "unknown")")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[WorkoutManager] 위치 오류 - \(error)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRecordingQuarter else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}
