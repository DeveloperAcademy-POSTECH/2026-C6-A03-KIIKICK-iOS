//
//  HeatmapRenderer.swift
//  KIIKICK
//
//  히트맵을 실제로 어떻게 그릴지는 이 프로토콜 뒤로 숨긴다.
//  지금은 그리드 밀도 방식(GridDensityHeatmapRenderer)만 있고,
//  나중에 보간/스무딩이 들어간 다른 구현으로 교체 가능하다.
//

import SwiftUI

protocol HeatmapRenderer {
    /// normalizedPoints: 운동장 내 정규화 좌표 (x: 0...1, y: 0...1). 범위를 벗어난 점은 구현체가 알아서 무시해도 된다.
    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint])
}

struct GridDensityHeatmapRenderer: HeatmapRenderer {
    let columns: Int
    let rows: Int
    
    init(columns: Int = 20, rows: Int = 13) {
        self.columns = columns
        self.rows = rows
    }
    
    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint]) {
        guard !normalizedPoints.isEmpty else { return }
        
        var counts = [Int](repeating: 0, count: columns * rows)
        for point in normalizedPoints {
            guard point.x >= 0, point.x <= 1, point.y >= 0, point.y <= 1 else { continue }
            let col = min(columns - 1, max(0, Int(point.x * CGFloat(columns))))
            let row = min(rows - 1, max(0, Int(point.y * CGFloat(rows))))
            counts[row * columns + col] += 1
        }
        
        guard let maxCount = counts.max(), maxCount > 0 else { return }
        
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)
        
        for row in 0..<rows {
            for col in 0..<columns {
                let count = counts[row * columns + col]
                guard count > 0 else { continue }
                let opacity = Double(count) / Double(maxCount)
                let rect = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                context.fill(Path(rect), with: .color(.red.opacity(0.15 + opacity * 0.65)))
            }
        }
    }
}
