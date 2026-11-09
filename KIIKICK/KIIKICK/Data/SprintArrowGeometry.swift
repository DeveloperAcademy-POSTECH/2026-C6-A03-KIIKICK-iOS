import CoreGraphics
import Foundation

/// 실제 경로 보간이 아닌 A→B 표시용 곡선. 곡률은 길이에 비례해 화면 크기에 대응한다.
struct SprintArrowGeometry {
    let start: CGPoint
    let end: CGPoint
    let control: CGPoint

    init?(start: CGPoint, end: CGPoint, curvature: CGFloat = 0.18) {
        guard start.x.isFinite, start.y.isFinite, end.x.isFinite, end.y.isFinite,
              curvature.isFinite else { return nil }
        let dx = end.x - start.x, dy = end.y - start.y
        guard hypot(dx, dy) > 0.01 else { return nil }
        self.start = start
        self.end = end
        self.control = CGPoint(x: (start.x + end.x) / 2 - dy * curvature,
                               y: (start.y + end.y) / 2 + dx * curvature)
    }

    /// 이차 Bézier 곡선의 끝 접선: control → end.
    var endAngle: CGFloat { atan2(end.y - control.y, end.x - control.x) }
}
