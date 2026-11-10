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
        var counts = [Double](repeating: 0, count: columns * rows)
        for point in points {
            guard point.x.isFinite, point.y.isFinite,
                  (0...1).contains(point.x), (0...1).contains(point.y) else { continue }
            let column = min(columns - 1, Int(point.x * CGFloat(columns)))
            let row = min(rows - 1, Int(point.y * CGFloat(rows)))
            counts[row * columns + column] += 1
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
