import SwiftUI

protocol HeatmapRenderer {
    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint])
    func render(in context: GraphicsContext, size: CGSize, weightedNormalizedPoints: [WeightedHeatmapPoint])
}

struct GridDensityHeatmapRenderer: HeatmapRenderer {
    let density: HeatmapDensity

    // Figma Color / Dark: dataviz/heatmap-low → mid → high.
    private let palette: [Color] = [.blue100, .blue300, .blue500]

    init(columns: Int = 80, rows: Int = 52, smoothingRadius: Int = 4) {
        density = HeatmapDensity(columns: columns, rows: rows, smoothingRadius: smoothingRadius)
    }

    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint]) {
        render(in: context, size: size, weightedNormalizedPoints: normalizedPoints.map { WeightedHeatmapPoint(location: $0, weight: 1) })
    }

    func render(in context: GraphicsContext, size: CGSize, weightedNormalizedPoints: [WeightedHeatmapPoint]) {
        let values = density.values(for: weightedNormalizedPoints)
        let width = size.width / CGFloat(density.columns)
        let height = size.height / CGFloat(density.rows)
        context.drawLayer { layer in
            // 셀 단위 계산 결과의 경계를 부드럽게 연결한다. 필드 선에는 블러를 적용하지 않는다.
            layer.addFilter(.blur(radius: min(width, height)))
            for (index, value) in values.enumerated() where value > 0 {
                let progress = value * Double(palette.count - 1)
                let lower = min(palette.count - 2, Int(progress))
                let color = palette[lower].mix(with: palette[lower + 1], by: progress - Double(lower))
                let rect = CGRect(x: CGFloat(index % density.columns) * width,
                                  y: CGFloat(index / density.columns) * height, width: width, height: height)
                layer.fill(Path(rect), with: .color(color.opacity(min(1, value * 4))))
            }
        }
    }
}
