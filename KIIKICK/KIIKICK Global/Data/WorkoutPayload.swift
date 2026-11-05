//
//  WorkoutPayload.swift
//  KIIKICK Global
//

import CoreLocation
import Foundation

struct WorkoutPayload: Codable {
    let startDate: Date
    let endDate: Date
    let points: [TrackPoint]
    let heartRateSamples: [HeartRateSample]
    let totalCalories: Double 
    let totalDistance: Double
}
