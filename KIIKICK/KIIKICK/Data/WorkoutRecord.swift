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
    var field: Field?

    init(payload: WorkoutPayload) {
        self.date = payload.startDate
        self.duration = payload.endDate.timeIntervalSince(payload.startDate)
        self.totalCalories = payload.totalCalories
        self.totalDistance = payload.totalDistance
        self.points = payload.points
        self.heartRateSamples = payload.heartRateSamples
    }
}

#if DEBUG
extension WorkoutPayload {
    static func fake() -> WorkoutPayload {
        let baseLatitude = 37.5665
        let baseLongitude = 126.9780
        let start = Date().addingTimeInterval(-600)
        let sampleCount = 120
        
        var points: [TrackPoint] = []
        var heartRateSamples: [HeartRateSample] = []
        
        for i in 0..<sampleCount {
            let timestamp = start.addingTimeInterval(Double(i) * 5)
            let angle = Double(i) * 0.15
            points.append(TrackPoint(
                latitude: baseLatitude + sin(angle) * 0.0004,
                longitude: baseLongitude + cos(angle) * 0.0004,
                altitude: 20,
                horizontalAccuracy: 5,
                speed: Double.random(in: 0...5),
                course: angle.truncatingRemainder(dividingBy: .pi * 2) * 180 / .pi,
                timestamp: timestamp
            ))
            heartRateSamples.append(HeartRateSample(timestamp: timestamp, bpm: Double.random(in: 90...170)))
        }
        
        return WorkoutPayload(
            startDate: start,
            endDate: start.addingTimeInterval(Double(sampleCount) * 5),
            points: points,
            heartRateSamples: heartRateSamples,
            totalCalories: Double.random(in: 300...600),
            totalDistance: Double.random(in: 2000...4000)
        )
    }
}
#endif
