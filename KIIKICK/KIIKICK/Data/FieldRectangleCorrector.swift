//
//  FieldRectangleCorrector.swift
//  KIIKICK
//
//  사용자가 순서대로 찍은 4개 핀(raw, 직사각형이 아닐 수 있음)을 실제 직사각형으로
//  보정한다. 등록 시점에 1회만 돌리고, 그 결과(Field.cornerA~D)로 히트맵 등 실제 연산을
//  전부 처리한다 — 설계 배경은 docs/superpowers/specs/2026-11-06-field-rectangle-correction-design.md.
//
//  기준각은 "탭 순서" 방식(1→2번 핀을 잇는 변의 각도)을 그대로 쓴다. AGENTS.md의
//  "핀 순서가 터치라인/골라인 방향을 정의한다"는 규칙과 맞물리고 계산이 제일 단순하다.
//  (다른 후보: 대변 평균 / 최장변 기준 / 최소자승 피팅 — 인터랙티브 비교는 위 스펙 문서 링크 참고)
//
//  보정은 기준각으로 4점을 회전시킨 좌표계에서 min/max로 바운딩 박스를 구하는 방식이라,
//  입력값 4점을 구조적으로 전부 포함하도록 항상 바깥으로만 확장되고 안쪽으로 깎이지 않는다.
//

import CoreLocation
import CoreGraphics

enum FieldRectangleCorrector {
    /// raw[0], raw[1], raw[2], raw[3] 순서(사용자가 찍은 순서)를 그대로 유지한 보정된
    /// 직사각형 네 꼭짓점을 돌려준다.
    static func correct(rawCorners: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        precondition(rawCorners.count == 4, "4개 좌표가 필요합니다")

        let plane = LocalPlane(reference: rawCorners[0])
        let points = rawCorners.map(plane.toLocal)

        // 1→2번 핀을 잇는 첫 변의 각도를 기준각으로 사용 (탭 순서 기준).
        let e1 = CGPoint(x: points[1].x - points[0].x, y: points[1].y - points[0].y)
        let theta = atan2(e1.y, e1.x)

        let c = cos(theta), s = sin(theta)
        let rotated = points.map { CGPoint(x: $0.x * c + $0.y * s, y: -$0.x * s + $0.y * c) }

        let minX = rotated.map(\.x).min()!, maxX = rotated.map(\.x).max()!
        let minY = rotated.map(\.y).min()!, maxY = rotated.map(\.y).max()!

        // 바운딩 박스 네 꼭짓점을 topLeading/topTrailing/bottomTrailing/bottomLeading
        // 순서(FieldCreationView의 cornerOrder와 동일한 규칙)로 되돌린다.
        let boxCorners = [
            CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: minY),
            CGPoint(x: maxX, y: maxY), CGPoint(x: minX, y: maxY)
        ]
        let back = boxCorners.map { CGPoint(x: $0.x * c - $0.y * s, y: $0.x * s + $0.y * c) }

        return back.map(plane.toCoordinate)
    }
}

/// 기준점 근처(운동장 크기, 최대 수백 미터)에서만 쓰는 최소 로컬 평면 근사.
/// 경도 1도의 실제 거리는 위도에 따라 cos(위도)배로 줄어들기 때문에, 이를 보정하지
/// 않으면 (경도, 위도)를 그냥 평면으로 취급했을 때 회전된 사각형이 비뚤어진다.
/// 더 넓은 범위에서 재사용할 일반 ENU/UTM 변환 유틸은 범위 밖(위 스펙 문서 참고) —
/// 여기서는 이 보정 한 번에만 쓰는 축소판.
private struct LocalPlane {
    private let referenceLatitude: CLLocationDegrees
    private let referenceLongitude: CLLocationDegrees
    private let metersPerDegreeLat: Double = 111_320.0
    private let metersPerDegreeLon: Double

    init(reference: CLLocationCoordinate2D) {
        referenceLatitude = reference.latitude
        referenceLongitude = reference.longitude
        metersPerDegreeLon = metersPerDegreeLat * cos(reference.latitude * .pi / 180)
    }

    func toLocal(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        CGPoint(
            x: (coordinate.longitude - referenceLongitude) * metersPerDegreeLon,
            y: (coordinate.latitude - referenceLatitude) * metersPerDegreeLat
        )
    }

    func toCoordinate(_ point: CGPoint) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: referenceLatitude + Double(point.y) / metersPerDegreeLat,
            longitude: referenceLongitude + Double(point.x) / metersPerDegreeLon
        )
    }
}
