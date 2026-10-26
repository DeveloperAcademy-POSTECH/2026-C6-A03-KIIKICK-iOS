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

    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var distance: Double = 0
    var speed: Double = 0

    func start() async {
        await requestAuthorization()

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

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
        } catch {
            print("[WorkoutManager] 세션 시작 실패 - \(error)")
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
                let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                DispatchQueue.main.async { self.heartRate = value }
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
