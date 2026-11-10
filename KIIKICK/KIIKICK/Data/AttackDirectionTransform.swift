import CoreGraphics

/// 원본 GPS는 유지하고 정규화한 표시 좌표만 운동장 중심을 기준으로 180° 회전한다.
struct AttackDirectionTransform {
    let isReversed: Bool

    func apply(to point: CGPoint) -> CGPoint {
        isReversed ? CGPoint(x: 1 - point.x, y: 1 - point.y) : point
    }
}
