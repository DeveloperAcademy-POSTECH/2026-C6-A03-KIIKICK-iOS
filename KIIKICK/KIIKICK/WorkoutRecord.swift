//
//  WorkoutRecord.swift
//  KIIKICK
//

import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var date: Date
    var duration: TimeInterval
    var totalCalories: Double
    var totalDistance: Double
    var points: [TrackPoint]
    var heartRateSamples: [HeartRateSample]

    init(payload: WorkoutPayload) {
        self.date = payload.startDate
        self.duration = payload.endDate.timeIntervalSince(payload.startDate)
        self.totalCalories = payload.totalCalories
        self.totalDistance = payload.totalDistance
        self.points = payload.points
        self.heartRateSamples = payload.heartRateSamples
    }
}
