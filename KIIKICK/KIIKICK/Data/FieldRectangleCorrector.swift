//
//  FieldRectangleCorrector.swift
//  KIIKICK
//
//  사용자가 찍은 4개 핀(raw, 순서·직사각형 여부 모두 보장 안 됨)을 실제 직사각형으로
//  보정한다. 등록 시점에 1회만 돌리고, 그 결과(Field.cornerA~D)로 히트맵 등 실제 연산을
//  전부 처리한다 — 설계 배경은 docs/superpowers/specs/2026-11-06-field-rectangle-correction-design.md.
//
//  탭 순서는 신뢰하지 않는다 — 사용자가 둘레를 따라 순서대로 찍는다는 보장이 없고,
//  순서에 의미를 두면 사용자가 실수로 다르게 찍었을 때 보정이 크게 틀어질 위험이 있다.
//  대신 4점의 중앙값(centroid)을 구하고, 그 중앙값 기준 각도로 정렬해서 항상 올바른
//  둘레 순서(시계방향)를 직접 만든다 — 사용자가 어떤 순서로 찍든 결과가 같다.
//
//  기준각은 "최장변 기준"을 쓴다 — 중앙값 정렬로 만든 4개 변 중 가장 긴 변의 각도를
//  쓰면, 축구/풋살 운동장은 터치라인(긴 변)이 골라인(짧은 변)보다 뚜렷이 길기 때문에
//  어느 변을 기준으로 잡아도 안정적으로 터치라인 방향이 나온다.
//  (다른 후보: 대변 평균 / 탭 순서 / 최소자승 피팅 — 인터랙티브 비교는 위 스펙 문서 링크 참고)
//
//  보정은 기준각으로 4점을 회전시킨 좌표계에서 min/max로 바운딩 박스를 구하는 방식이라,
//  입력값 4점을 구조적으로 전부 포함하도록 항상 바깥으로만 확장되고 안쪽으로 깎이지 않는다.
//

import CoreLocation
import CoreGraphics

enum FieldRectangleCorrector {
    /// 보정된 직사각형 네 꼭짓점을 시계방향 순서로 돌려준다. 입력 `rawCorners`의 순서는
    /// 결과에 영향을 주지 않는다 — 내부적으로 중앙값 기준 각도 정렬로 다시 순서를 매긴다.
    static func correct(rawCorners: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        precondition(rawCorners.count == 4, "4개 좌표가 필요합니다")

        let plane = LocalPlane(reference: rawCorners[0])
        let rawPoints = rawCorners.map(plane.toLocal)

        // 중앙값 기준 각도로 정렬해 시계방향 둘레 순서를 만든다. 로컬 평면은
        // x=동쪽·y=북쪽이라, 지도를 북쪽이 위로 가게 봤을 때 시계방향(북→동→남→서)은
        // atan2(y, x)가 "감소"하는 방향이다 — 그래서 내림차순으로 정렬한다.
        let centroid = CGPoint(
            x: rawPoints.map(\.x).reduce(0, +) / 4,
            y: rawPoints.map(\.y).reduce(0, +) / 4
        )
        let points = rawPoints.sorted { a, b in
            atan2(a.y - centroid.y, a.x - centroid.x) > atan2(b.y - centroid.y, b.x - centroid.x)
        }

        // 중앙값 정렬로 만든 4개 변(0→1, 1→2, 2→3, 3→0) 중 가장 긴 변의 각도를
        // 기준각으로 쓴다 (최장변 기준).
        let theta = (0..<4)
            .map { i -> (angle: CGFloat, length: CGFloat) in
                let a = points[i]
                let b = points[(i + 1) % 4]
                let dx = b.x - a.x, dy = b.y - a.y
                return (atan2(dy, dx), (dx * dx + dy * dy).squareRoot())
            }
            .max { $0.length < $1.length }!
            .angle

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
