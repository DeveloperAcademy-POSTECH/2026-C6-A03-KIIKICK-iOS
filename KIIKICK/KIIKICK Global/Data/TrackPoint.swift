//
//  TrackPoint.swift
//  KIIKICK Global
//
//  Created by Seungjun Lee on 10/31/26.
//

import CoreLocation
import Foundation

struct TrackPoint: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let speed: Double
    let course: Double
    let timestamp: Date
    
    init(latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, speed: Double, course: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.course = course
        self.timestamp = timestamp
    }
    
    init(location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed,
            course: location.course,
            timestamp: location.timestamp
        )
    }
}
