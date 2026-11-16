import SwiftUI

struct MockHeatmapFieldView: View {
    let points: [MockHeatmapPoint]
    let selectedPoint: MockHeatmapPoint?
    let showsTrail: Bool

    init(points: [MockHeatmapPoint], selectedPoint: MockHeatmapPoint? = nil, showsTrail: Bool = false) {
        self.points = points
        self.selectedPoint = selectedPoint
        self.showsTrail = showsTrail
    }

    var body: some View {
        FieldCanvasView { context, size in
            var drawingContext = context
            let normalizedPoints = points.map(\.normalizedPoint)
            GridDensityHeatmapRenderer().render(
                in: drawingContext,
                size: size,
                normalizedPoints: normalizedPoints
            )

            if showsTrail {
                drawTrail(in: &drawingContext, size: size)
            }
            if let selectedPoint {
                drawSelectedPoint(selectedPoint, in: &drawingContext, size: size)
            }
        }
        .accessibilityLabel("목업 히트맵")
    }

    private func drawTrail(in context: inout GraphicsContext, size: CGSize) {
        guard points.count > 1 else { return }
        var path = Path()
        for (index, point) in points.enumerated() {
            let location = CGPoint(
                x: point.normalizedX * size.width,
                y: point.normalizedY * size.height
            )
            if index == 0 {
                path.move(to: location)
            } else {
                path.addLine(to: location)
            }
        }
        context.stroke(path, with: .color(.white.opacity(0.45)), lineWidth: 1.5)
    }

    private func drawSelectedPoint(_ point: MockHeatmapPoint, in context: inout GraphicsContext, size: CGSize) {
        let location = CGPoint(
            x: point.normalizedX * size.width,
            y: point.normalizedY * size.height
        )
        let radius = min(size.width, size.height) * 0.025
        let rect = CGRect(x: location.x - radius, y: location.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(.white))
        context.stroke(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(.black), lineWidth: 1)
    }
}
