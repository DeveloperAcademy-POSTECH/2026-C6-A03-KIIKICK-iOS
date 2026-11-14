import Foundation
import CoreGraphics
import CoreLocation

@main
struct TrackingMapsChecks {
    static func main() {
        // 가로·세로·회전 운동장 모두 실제 100m 긴 변이 정규화 x축에 대응해야 한다.
        for angle in [0.0, .pi / 2, .pi / 6, -.pi / 3] {
            let local = [CGPoint(x: -50, y: -30), CGPoint(x: 50, y: -30),
                         CGPoint(x: 50, y: 30), CGPoint(x: -50, y: 30)]
            let corners = local.map { point in
                let x = point.x * cos(angle) - point.y * sin(angle)
                let y = point.x * sin(angle) + point.y * cos(angle)
                return CLLocationCoordinate2D(latitude: 37 + y / 111_320,
                    longitude: 127 + x / (111_320 * cos(37 * .pi / 180)))
            }
            for input in [corners, Array(corners.reversed()), [corners[2], corners[0], corners[3], corners[1]]] {
                let mapper = FieldCoordinateMapper(corners: input)
                precondition(abs(mapper.horizontalLengthMeters - 100) < 0.01)
                precondition(abs(mapper.verticalLengthMeters - 60) < 0.01)
                let a = mapper.normalize(corners[0]), b = mapper.normalize(corners[1])
                precondition(abs(abs(b.x - a.x) - 1) < 1e-7 && abs(b.y - a.y) < 1e-7,
                    "운동장 긴 변이 정규화 가로축에 배치되어야 한다")
                let c = mapper.normalize(corners[3])
                let handedness = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
                precondition(handedness < 0,
                    "북쪽이 위인 실제 좌표를 화면의 아래로 증가하는 세로축에 옮길 때 거울상이 생기면 안 된다")
                let center = mapper.normalize(CLLocationCoordinate2D(latitude: 37, longitude: 127))
                precondition(abs(center.x - 0.5) < 1e-7 && abs(center.y - 0.5) < 1e-7)
            }
        }

        let eastWest = FieldCoordinateMapper(corners: [
            CLLocationCoordinate2D(latitude: 37, longitude: 127),
            CLLocationCoordinate2D(latitude: 37, longitude: 127.002),
            CLLocationCoordinate2D(latitude: 37.001, longitude: 127.002),
            CLLocationCoordinate2D(latitude: 37.001, longitude: 127)
        ])
        let northWest = eastWest.normalize(CLLocationCoordinate2D(latitude: 37.001, longitude: 127))
        let southWest = eastWest.normalize(CLLocationCoordinate2D(latitude: 37, longitude: 127))
        precondition(abs(northWest.x) < 1e-7 && abs(northWest.y) < 1e-7)
        precondition(abs(southWest.x) < 1e-7 && abs(southWest.y - 1) < 1e-7)

        let density = HeatmapDensity(columns: 4, rows: 4, smoothingRadius: 0)
        let values = density.values(for: [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 1), CGPoint(x: -0.1, y: 0), CGPoint(x: CGFloat.nan, y: 0)])
        precondition(values[0] == 1 && values[15] == 0.5)
        precondition(values.filter { $0 > 0 }.count == 2, "운동장 밖 포인트를 경계에 누적하지 않아야 한다")
        precondition(density.values(for: [CGPoint]()).allSatisfy { $0 == 0 })
        let smoothed = HeatmapDensity(columns: 5, rows: 5, smoothingRadius: 2)
            .values(for: [CGPoint(x: 0.5, y: 0.5)])
        precondition(smoothed[12] == 1 && smoothed[11] > smoothed[10] && smoothed[10] > 0)
        precondition(smoothed[11] == smoothed[13] && smoothed[7] == smoothed[17])

        let artwork = FieldArtworkLayout.artworkSize
        let fieldRect = FieldArtworkLayout.fieldRect(in: artwork)
        precondition(fieldRect == CGRect(x: 99, y: 102, width: 1338, height: 820))
        precondition(FieldArtworkLayout.pixel(for: .zero, in: artwork) == fieldRect.origin)
        let center = FieldArtworkLayout.pixel(for: CGPoint(x: 0.5, y: 0.5), in: artwork)
        precondition(center == CGPoint(x: fieldRect.midX, y: fieldRect.midY))
        let fitted = FieldArtworkLayout.fieldRect(in: CGSize(width: 1536, height: 1200))
        precondition(fitted.minY == fieldRect.minY + 88 && fitted.width == fieldRect.width)

        let transform = AttackDirectionTransform(isReversed: true)
        let point = CGPoint(x: 0.2, y: 0.7)
        let restored = transform.apply(to: transform.apply(to: point))
        precondition(abs(restored.x - point.x) < 1e-12 && abs(restored.y - point.y) < 1e-12)
        precondition(transform.apply(to: CGPoint(x: 0.5, y: 0.5)) == CGPoint(x: 0.5, y: 0.5))
        precondition(AttackDirectionTransform(isReversed: false).apply(to: point) == point)

        func sample(_ second: Double, _ kmh: Double) -> TrackPoint {
            TrackPoint(latitude: 37, longitude: 127, altitude: 0, horizontalAccuracy: 3,
                speed: kmh / 3.6, course: 0, timestamp: Date(timeIntervalSince1970: second))
        }
        let curve = SprintArrowGeometry(start: .zero, end: CGPoint(x: 100, y: 0))!
        precondition(curve.control.y > 0 && curve.control.x == 50)
        precondition(curve.endAngle < 0, "화살촉은 곡선 끝의 접선을 따라야 한다")
        precondition(SprintArrowGeometry(start: .zero, end: .zero) == nil)
        precondition(SprintArrowGeometry(start: CGPoint(x: CGFloat.nan, y: 0), end: .zero) == nil)
        let rotatedCurve = SprintArrowGeometry(start: CGPoint(x: 100, y: 100), end: CGPoint(x: 0, y: 100))!
        precondition(abs(rotatedCurve.control.y - (100 - curve.control.y)) < 1e-12)

        let detector = SprintDetector(speedThresholdKmh: 21, minimumDistanceMeters: 0)
        precondition(detector.detect(in: [sample(0, 21), sample(1, 21)]).isEmpty)
        let input = [sample(0, 22), sample(1, 23), sample(2, 20), sample(3, 24), sample(4, 25)]
        let sprints = detector.detect(in: Array(input.reversed()))
        precondition(sprints.count == 2 && sprints[0].start.timestamp == input[0].timestamp)
        precondition(sprints[1].end.timestamp == input[4].timestamp)
        precondition(detector.detect(in: [sample(0, 22)]).isEmpty)
        precondition(detector.detect(in: [sample(0, .infinity), sample(1, 22)]).isEmpty)
        func movingSample(_ second: Double, longitude: Double, speed: Double = 22) -> TrackPoint {
            TrackPoint(latitude: 0, longitude: longitude, altitude: 0, horizontalAccuracy: 3,
                speed: speed / 3.6, course: 0, timestamp: Date(timeIntervalSince1970: second))
        }
        let distanceDetector = SprintDetector(speedThresholdKmh: 21)
        #if DEBUG
        precondition(abs(SprintDetector().speedThreshold - 13 / 3.6) < 1e-12)
        #else
        precondition(abs(SprintDetector().speedThreshold - 21 / 3.6) < 1e-12)
        #endif
        let start = movingSample(0, longitude: 0)
        precondition(distanceDetector.detect(in: [start, movingSample(1, longitude: 0.00008)]).isEmpty,
            "10m 미만은 표시하지 않는다")
        precondition(distanceDetector.detect(in: [start, movingSample(1, longitude: 0.0001)]).count == 1,
            "10m 이상은 표시한다")
        let turningRun = [start, movingSample(1, longitude: 0.0001),
            movingSample(2, longitude: 0.00005), movingSample(3, longitude: 0.00015)]
        precondition(distanceDetector.detect(in: Array(turningRun.reversed())).count == 1,
            "시작/끝 직선거리 대신 실제 누적 경로 거리를 사용한다")
        let splitRuns = [start, movingSample(1, longitude: 0.00006),
            movingSample(2, longitude: 0.00007, speed: 20),
            movingSample(3, longitude: 0.00008), movingSample(4, longitude: 0.00014)]
        precondition(distanceDetector.detect(in: splitRuns).isEmpty,
            "속도가 떨어진 두 구간의 거리를 합치지 않는다")
        let exactDistance = CLLocation(latitude: 0, longitude: 0)
            .distance(from: CLLocation(latitude: 0, longitude: 0.0002))
        precondition(SprintDetector(speedThresholdKmh: 21, minimumDistanceMeters: exactDistance)
            .detect(in: [start, movingSample(1, longitude: 0.0002)]).count == 1,
            "최소 거리와 같은 구간도 포함한다")
        print("Tracking map checks passed: density boundaries/smoothing, rotation, sprint threshold/grouping.")
    }
}
