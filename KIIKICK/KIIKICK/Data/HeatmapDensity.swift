import Foundation
import CoreGraphics

/// 교체 가능한 상대 밀도 계산. 운동장 밖 좌표는 경계로 몰아넣지 않고 제외한다.
struct HeatmapDensity {
    let columns: Int
    let rows: Int
    let smoothingRadius: Int

    init(columns: Int = 80, rows: Int = 52, smoothingRadius: Int = 4) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.smoothingRadius = max(0, smoothingRadius)
    }

    func values(for points: [CGPoint]) -> [Double] {
        values(for: points.map { WeightedHeatmapPoint(location: $0, weight: 1) })
    }

    /// 원본 GPS를 공개하지 않는 친구 히트맵은 서버가 격자별 표본 수를 준다.
    /// 같은 좌표를 표본 수만큼 복제하지 않고 가중치로 누적한다.
    func values(for points: [WeightedHeatmapPoint]) -> [Double] {
        var counts = [Double](repeating: 0, count: columns * rows)
        for point in points {
            guard point.location.x.isFinite, point.location.y.isFinite,
                  point.weight.isFinite, point.weight > 0,
                  (0...1).contains(point.location.x), (0...1).contains(point.location.y) else { continue }
            let column = min(columns - 1, Int(point.location.x * CGFloat(columns)))
            let row = min(rows - 1, Int(point.location.y * CGFloat(rows)))
            counts[row * columns + column] += point.weight
        }
        var density = counts
        if smoothingRadius > 0 {
            density = [Double](repeating: 0, count: counts.count)
            let sigma = max(1, Double(smoothingRadius) / 2)
            for row in 0..<rows {
                for column in 0..<columns where counts[row * columns + column] > 0 {
                    for dy in -smoothingRadius...smoothingRadius {
                        for dx in -smoothingRadius...smoothingRadius {
                            let x = column + dx, y = row + dy
                            guard x >= 0, x < columns, y >= 0, y < rows else { continue }
                            let weight = exp(-Double(dx * dx + dy * dy) / (2 * sigma * sigma))
                            density[y * columns + x] += counts[row * columns + column] * weight
                        }
                    }
                }
            }
        }
        guard let peak = density.max(), peak > 0 else { return density }
        return density.map { $0 / peak }
    }
}

struct WeightedHeatmapPoint {
    let location: CGPoint
    let weight: Double
}
