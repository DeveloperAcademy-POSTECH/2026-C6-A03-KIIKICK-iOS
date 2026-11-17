import Foundation
import SwiftUI

@MainActor
enum MockHeatmapAnalysisAdapter {
    private static let centerLatitude = 37.5665
    private static let centerLongitude = 126.9780
    private static let metersPerLatitudeDegree = 111_320.0
    private static let metersPerLongitudeDegree = 88_500.0
    private static let fieldLength = 105.0
    private static let fieldWidth = 68.0
    /// 목업 원본은 5초 간격으로 생성되지만, 타임라인 재생은 1초 간격으로 보간한다.
    /// 실제 워치 데이터의 샘플 주기와 무관하게 목업 화면에서 위치가 끊겨 보이지 않게 한다.
    private static let interpolationInterval: TimeInterval = 1
    static let defaultFieldName = "풋살장"

    static func field() -> Field {
        let topLatitude = centerLatitude + fieldWidth / 2 / metersPerLatitudeDegree
        let bottomLatitude = centerLatitude - fieldWidth / 2 / metersPerLatitudeDegree
        let leftLongitude = centerLongitude - fieldLength / 2 / metersPerLongitudeDegree
        let rightLongitude = centerLongitude + fieldLength / 2 / metersPerLongitudeDegree
        return Field(
            name: defaultFieldName,
            cornerA: FieldCorner(latitude: topLatitude, longitude: leftLongitude),
            cornerB: FieldCorner(latitude: topLatitude, longitude: rightLongitude),
            cornerC: FieldCorner(latitude: bottomLatitude, longitude: rightLongitude),
            cornerD: FieldCorner(latitude: bottomLatitude, longitude: leftLongitude)
        )
    }

    static func quarter(_ quarter: MockHeatmapQuarter) -> AnalysisQuarter {
        let startDate = quarter.points.first?.timestamp
        let interpolatedPoints = interpolate(quarter.points, interval: interpolationInterval)
        var result = AnalysisQuarter(
            quarterNumber: quarter.number,
            durationText: durationText(quarter.duration),
            startDate: startDate,
            duration: quarter.duration,
            field: field(),
            points: interpolatedPoints.map(trackPoint),
            events: quarter.events.compactMap { event -> AnalysisMatchEvent? in
                guard let point = quarter.points[safe: event.pointIndex], let startDate else { return nil }
                let type: TimelineEventType = event.type == .goal ? .goal : .assist
                return AnalysisMatchEvent(
                    id: UUID(uuidString: event.id) ?? UUID(),
                    type: type,
                    timeText: durationText(event.timestamp.timeIntervalSince(startDate)),
                    timestamp: event.timestamp,
                    position: UnitPoint(x: point.normalizedX, y: point.normalizedY)
                )
            },
            totalDistanceKm: totalDistanceKm(quarter.points),
            totalCaloriesKcal: caloriesKcal(for: quarter)
        )
        result.isAttackDirectionReversed = quarter.isAttackDirectionReversed
        return result
    }

    /// 생성된 이동 속도와 심박 강도를 반영해 쿼터별 소모 칼로리를 계산한다.
    /// 같은 포지션이어도 시드가 달라지면 값이 조금씩 달라지도록 한다.
    static func caloriesKcal(for quarter: MockHeatmapQuarter) -> Double {
        guard !quarter.points.isEmpty else { return quarter.duration / 60 * 9 }

        let averageHeartRate = quarter.points.map(\.heartRateBpm).reduce(0, +) / Double(quarter.points.count)
        let averageSpeed = quarter.points.map(\.speedMps).reduce(0, +) / Double(quarter.points.count)
        let heartRateIntensity = min(max((averageHeartRate - 95) / 100, 0), 1)
        let caloriesPerMinute = 7.5 + heartRateIntensity * 2.6 + min(averageSpeed, 4) * 0.15
        return (quarter.duration / 60 * caloriesPerMinute * 10).rounded() / 10
    }

    static func trackPoint(_ point: MockHeatmapPoint) -> TrackPoint {
        let latitude = centerLatitude + (fieldWidth / 2 - point.yMeters) / metersPerLatitudeDegree
        let longitude = centerLongitude + (point.xMeters - fieldLength / 2) / metersPerLongitudeDegree
        return TrackPoint(
            latitude: latitude,
            longitude: longitude,
            altitude: 0,
            horizontalAccuracy: 3,
            speed: point.speedMps,
            course: 0,
            timestamp: point.timestamp
        )
    }

    /// 두 목업 샘플 사이의 위치·속도를 선형 보간해 타임라인에 전달할 포인트를 만든다.
    /// 원본 포인트는 그대로 보존하고, 중간 시각에만 새 포인트를 삽입한다.
    private static func interpolate(
        _ points: [MockHeatmapPoint],
        interval: TimeInterval
    ) -> [MockHeatmapPoint] {
        guard points.count > 1, interval > 0 else { return points }

        var result: [MockHeatmapPoint] = []
        result.reserveCapacity(points.count * 5)

        for index in 0..<(points.count - 1) {
            let start = points[index]
            let end = points[index + 1]
            let duration = end.timestamp.timeIntervalSince(start.timestamp)

            if index == 0 {
                result.append(start)
            }

            if duration > interval {
                var elapsed = interval
                while elapsed < duration {
                    let progress = elapsed / duration
                    result.append(interpolatedPoint(from: start, to: end, progress: progress))
                    elapsed += interval
                }
            }

            // 구간의 끝 원본 샘플을 보존한다. 다음 구간의 시작과 중복되지 않도록
            // 다음 반복에서는 시작 샘플을 다시 추가하지 않는다.
            result.append(end)
        }

        return result
    }

    private static func interpolatedPoint(
        from start: MockHeatmapPoint,
        to end: MockHeatmapPoint,
        progress: Double
    ) -> MockHeatmapPoint {
        let clampedProgress = min(max(progress, 0), 1)
        func lerp(_ start: Double, _ end: Double) -> Double {
            start + (end - start) * clampedProgress
        }

        return MockHeatmapPoint(
            id: "\(start.id)-interpolated-\(Int(clampedProgress * 1_000))",
            timestamp: start.timestamp.addingTimeInterval(
                end.timestamp.timeIntervalSince(start.timestamp) * clampedProgress
            ),
            xMeters: lerp(start.xMeters, end.xMeters),
            yMeters: lerp(start.yMeters, end.yMeters),
            normalizedX: lerp(start.normalizedX, end.normalizedX),
            normalizedY: lerp(start.normalizedY, end.normalizedY),
            speedMps: lerp(start.speedMps, end.speedMps),
            heartRateBpm: lerp(start.heartRateBpm, end.heartRateBpm)
        )
    }

    static func totalDistanceMeters(_ points: [MockHeatmapPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        return zip(points, points.dropFirst()).reduce(0.0) { partialResult, pair in
            let dx = (pair.1.xMeters - pair.0.xMeters)
            let dy = (pair.1.yMeters - pair.0.yMeters)
            return partialResult + hypot(dx, dy)
        }
    }

    private static func totalDistanceKm(_ points: [MockHeatmapPoint]) -> Double {
        totalDistanceMeters(points) / 1_000
    }

    private static func durationText(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes.formatted(.number.precision(.integerLength(2)))):\(remainingSeconds.formatted(.number.precision(.integerLength(2))))"
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
