//
//  SprintMapView.swift
//  KIIKICK
//
//  시속 13km 이상으로 달린 구간을, 시작점 -> 끝점 화살표로 운동장 위에 표시한다.
//

import SwiftUI
import CoreLocation

struct SprintMapView: View {
    let field: Field
    let points: [TrackPoint]
    let detector: SprintDetector
    
    init(field: Field, points: [TrackPoint], detector: SprintDetector = SprintDetector()) {
        self.field = field
        self.points = points
        self.detector = detector
    }
    
    var body: some View {
        let mapper = FieldCoordinateMapper(field: field)
        let sprints = detector.detect(in: points)
        
        FieldCanvasView { context, size in
            for sprint in sprints {
                let start = normalizedPixel(for: sprint.start, mapper: mapper, size: size)
                let end = normalizedPixel(for: sprint.end, mapper: mapper, size: size)
                drawArrow(from: start, to: end, in: context)
            }
        }
    }
    
    private func normalizedPixel(for point: TrackPoint, mapper: FieldCoordinateMapper, size: CGSize) -> CGPoint {
        let normalized = mapper.normalize(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        return CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }
    
    private func drawArrow(from start: CGPoint, to end: CGPoint, in context: GraphicsContext) {
        var line = Path()
        line.move(to: start)
        line.addLine(to: end)
        context.stroke(line, with: .color(.orange), lineWidth: 2)
        
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 8
        let arrowAngle: CGFloat = .pi / 7
        
        let left = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let right = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var head = Path()
        head.move(to: left)
        head.addLine(to: end)
        head.addLine(to: right)
        context.stroke(head, with: .color(.orange), lineWidth: 2)
    }
}
