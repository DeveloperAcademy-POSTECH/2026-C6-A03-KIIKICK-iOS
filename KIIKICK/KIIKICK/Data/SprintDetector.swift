//
//  SprintDetector.swift
//  KIIKICK
//
//  속도(순간 speed)가 기준치 이상으로 유지되는 구간을 스프린트로 판정한다.
//

import Foundation

struct Sprint {
    let points: [TrackPoint]

    var start: TrackPoint { points[0] }
    var end: TrackPoint { points[points.count - 1] }
}

struct SprintDetector {
    
    let speedThreshold: Double // 임계 기준 속도
    
    init(speedThresholdKmh: Double = 13) {
        self.speedThreshold = speedThresholdKmh * 1000 / 3600
    }
    
    func detect(in points: [TrackPoint]) -> [Sprint] {
        var sprints: [Sprint] = []
        var current: [TrackPoint] = []
        
        for point in points { // points는 시간 순으로 정렬되어 있다.
            if point.speed >= speedThreshold {
                current.append(point)
            } else {
                if current.count >= 2 {
                    sprints.append(Sprint(points: current))
                }
                current = []
            }
        }
        if current.count >= 2 {
            sprints.append(Sprint(points: current))
        }
        
        return sprints
    }
}
