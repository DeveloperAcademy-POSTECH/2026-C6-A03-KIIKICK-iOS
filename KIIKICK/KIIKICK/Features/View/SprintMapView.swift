//
//  SprintMapView.swift
//  KIIKICK
//
//  시속 21km/h 초과(Debug는 13km/h), 누적 거리 10m 이상 구간을 곡선 화살표로 표시한다.
//

import SwiftUI
import CoreLocation

struct SprintMapView: View {
    let field: Field
    let points: [TrackPoint]
    let isAttackDirectionReversed: Bool
    let detector: SprintDetector
    
    init(field: Field, points: [TrackPoint], isAttackDirectionReversed: Bool = false, detector: SprintDetector = SprintDetector()) {
        self.field = field
        self.points = points
        self.isAttackDirectionReversed = isAttackDirectionReversed
        self.detector = detector
    }
    
    var body: some View {
        let mapper = FieldCoordinateMapper(field: field)
        let sprints = detector.detect(in: points)
        let visibleSprints = sprints.compactMap { sprint -> (CGPoint, CGPoint)? in
            let positions = sprint.points.compactMap { normalizedPosition(for: $0, mapper: mapper) }
            guard let start = positions.first, let end = positions.last, start != end else { return nil }
            return (start, end)
        }
        
        FieldCanvasView { context, size in
            if visibleSprints.isEmpty {
                drawEmptyMessage(in: context, size: size)
            } else {
                for (start, end) in visibleSprints {
                    drawArrow(
                        from: CGPoint(x: start.x * size.width, y: start.y * size.height),
                        to: CGPoint(x: end.x * size.width, y: end.y * size.height),
                        in: context, size: size
                    )
                }
            }
        }
        .accessibilityLabel(visibleSprints.isEmpty ? "기록된 스프린트가 없어요" : "스프린트 화살표 \(visibleSprints.count)개")
    }

    private func drawEmptyMessage(in context: GraphicsContext, size: CGSize) {
        let message = context.resolve(Text("21km/h로 10m 이상 뛴 스프린트가 없어요")
            .font(.body4R)
            .foregroundStyle(.colorTextPrimary))
        let textSize = message.measure(in: size)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let background = CGRect(x: center.x - textSize.width / 2 - 16,
                                y: center.y - textSize.height / 2 - 12,
                                width: textSize.width + 32, height: textSize.height + 24)
        context.fill(Path(roundedRect: background, cornerRadius: 8), with: .color(Color.gray900.opacity(0.9)))
        context.draw(message, at: center)
    }
    
    private func normalizedPosition(for point: TrackPoint, mapper: FieldCoordinateMapper) -> CGPoint? {
        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        let normalized = mapper.normalize(coordinate)
        // 운동장 밖 GPS 이상치로 매우 큰 곡선을 만들어 GPU에 넘기지 않는다.
        guard normalized.x.isFinite, normalized.y.isFinite,
              (0...1).contains(normalized.x), (0...1).contains(normalized.y) else { return nil }
        let display = AttackDirectionTransform(isReversed: isAttackDirectionReversed).apply(to: normalized)
        return display
    }
    
    private func drawArrow(from start: CGPoint, to end: CGPoint, in context: GraphicsContext, size: CGSize) {
        // DESIGN-GAP: Figma와 같은 A→B 곡선 표현. 정확한 곡률 수치는 미지정으로 설정값 사용.
        guard let curve = SprintArrowGeometry(start: start, end: end) else { return }
        let control = CGPoint(x: min(max(curve.control.x, 0), size.width),
                              y: min(max(curve.control.y, 0), size.height))
        var line = Path()
        line.move(to: start)
        line.addQuadCurve(to: end, control: control)
        context.stroke(line, with: .color(.lime500), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        
        let angle = atan2(end.y - control.y, end.x - control.x)
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
        head.closeSubpath()
        context.fill(head, with: .color(.lime500))
    }
}
