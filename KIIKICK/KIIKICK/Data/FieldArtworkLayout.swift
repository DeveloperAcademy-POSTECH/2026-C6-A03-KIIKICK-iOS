import CoreGraphics

/// img_field 원본(1536×1024)의 운동장 경계선 중심을 표시 좌표계로 사용한다.
/// 이미지 외곽 여백과 상단 공격 방향 표시는 데이터 영역에 포함하지 않는다.
struct FieldArtworkLayout {
    static let artworkSize = CGSize(width: 1536, height: 1024)
    // 원본 PNG의 경계선 위치를 기준으로 한 좌표. 에셋 교체 시 함께 갱신한다.
    private static let fieldBounds = CGRect(x: 99, y: 102, width: 1338, height: 820)

    static func fieldRect(in size: CGSize) -> CGRect {
        let scale = min(size.width / artworkSize.width, size.height / artworkSize.height)
        let origin = CGPoint(x: (size.width - artworkSize.width * scale) / 2,
                             y: (size.height - artworkSize.height * scale) / 2)
        return CGRect(x: origin.x + fieldBounds.minX * scale,
                      y: origin.y + fieldBounds.minY * scale,
                      width: fieldBounds.width * scale, height: fieldBounds.height * scale)
    }

    static func pixel(for point: CGPoint, in size: CGSize) -> CGPoint {
        let rect = fieldRect(in: size)
        return CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
    }
}
