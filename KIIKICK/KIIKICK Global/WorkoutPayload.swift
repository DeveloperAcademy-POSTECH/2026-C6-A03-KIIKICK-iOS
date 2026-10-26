//
//  WorkoutPayload.swift
//  KIIKICK Global
//

import Foundation

struct TrackPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

struct HeartRateSample: Codable {
    let timestamp: Date
    let bpm: Double
}

struct WorkoutPayload: Codable {
    let startDate: Date
    let endDate: Date
    let points: [TrackPoint]
    let heartRateSamples: [HeartRateSample]
    let totalCalories: Double
    let totalDistance: Double
}
