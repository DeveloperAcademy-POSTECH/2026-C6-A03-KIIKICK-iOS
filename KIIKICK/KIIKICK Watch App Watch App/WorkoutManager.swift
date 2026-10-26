//
//  WorkoutManager.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/27/26.
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

    var isRunning: Bool = false
    private(set) var points: [TrackPoint] = []
    private(set) var heartRateSamples: [HeartRateSample] = []

    func start() async {
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
            points = []
            heartRateSamples = []

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)

            isRunning = true
            locationManager.startUpdatingLocation()
        } catch {
            print("[WorkoutManager] 세션 시작 실패 - \(error)")
        }
    }

    func stop() async {
        locationManager.stopUpdatingLocation()

        guard let session = workoutSession, let builder = workoutBuilder else {
            isRunning = false
            return
        }

        let endDate = Date()
        let startDate = builder.startDate ?? endDate
        session.stopActivity(with: endDate)
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
        } catch {
            print("[WorkoutManager] 세션 종료 실패 - \(error)")
        }

        let payload = WorkoutPayload(
            startDate: startDate,
            endDate: endDate,
            points: points,
            heartRateSamples: heartRateSamples,
            totalCalories: activeEnergy,
            totalDistance: distance
        )
        SessionManager.shared.send(payload: payload)

        isRunning = false
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
                    self.heartRateSamples.append(sample)
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
        DispatchQueue.main.async { self.points.append(point) }
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
        guard isRunning else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}
