//
//  SprintDetector.swift
//  KIIKICK
//
//  속도(순간 speed)가 기준치 초과으로 유지되는 구간을 스프린트로 판정한다.
//

import Foundation
import CoreLocation

struct Sprint {
    let points: [TrackPoint]

    var start: TrackPoint { points[0] }
    var end: TrackPoint { points[points.count - 1] }
}

struct SprintDetector {
    
    let speedThreshold: Double // 임계 기준 속도
    let minimumDistanceMeters: Double
    
    init(speedThresholdKmh: Double = 21, minimumDistanceMeters: Double = 20) {
        self.speedThreshold = speedThresholdKmh * 1000 / 3600
        self.minimumDistanceMeters = max(0, minimumDistanceMeters)
    }
    
    func detect(in points: [TrackPoint]) -> [Sprint] {
        var sprints: [Sprint] = []
        var current: [TrackPoint] = []
        var currentDistance: Double = 0
        var previousLocation: CLLocation?
        
        for point in points.sorted(by: { $0.timestamp < $1.timestamp }) {
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            if point.speed.isFinite, point.speed > speedThreshold, CLLocationCoordinate2DIsValid(coordinate) {
                let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
                if let previousLocation {
                    currentDistance += location.distance(from: previousLocation)
                }
                current.append(point)
                previousLocation = location
            } else {
                if current.count >= 2, currentDistance >= minimumDistanceMeters {
                    sprints.append(Sprint(points: current))
                }
                current = []
                currentDistance = 0
                previousLocation = nil
            }
        }
        if current.count >= 2, currentDistance >= minimumDistanceMeters {
            sprints.append(Sprint(points: current))
        }
        
        return sprints
    }
}
