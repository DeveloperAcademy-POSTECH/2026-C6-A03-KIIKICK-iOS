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
    /// m/s 기준 임계 속도.
    let speedThreshold: Double

    init(speedThresholdKmh: Double = 13) {
        self.speedThreshold = speedThresholdKmh * 1000 / 3600
    }

    /// points는 시간순으로 정렬되어 있다고 가정한다.
    func detect(in points: [TrackPoint]) -> [Sprint] {
        var sprints: [Sprint] = []
        var current: [TrackPoint] = []

        for point in points {
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
