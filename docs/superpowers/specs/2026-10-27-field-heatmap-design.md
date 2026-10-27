# 운동장 등록 + 히트맵 Design

## Overview

iPhone에서 위성 지도에 핀 4개를 찍어 운동장을 등록하고, 측정 기록(`WorkoutRecord`)을 등록된 운동장에 연결하면, GPS 경로를 운동장 좌표계로 정규화해 히트맵으로 보여준다.

## 데이터 모델

```swift
struct FieldCorner: Codable {
    let latitude: Double
    let longitude: Double
}

@Model
final class Field {
    var name: String
    var cornerA: FieldCorner  // 4개 꼭짓점, 순서 무관
    var cornerB: FieldCorner
    var cornerC: FieldCorner
    var cornerD: FieldCorner
}
```

- 4개 꼭짓점은 사용자가 찍은 순서를 그대로 저장한다. 공격 방향(터치라인/골라인 구분)은 이번 범위에 포함하지 않으므로, 순서에 의미를 부여하지 않는다 — `FieldCoordinateMapper`가 bilinear 보간 전에 꼭짓점 좌표값(위도/경도 극값) 기준으로 좌상/우상/좌하/우하를 자체적으로 정렬한다.
- `WorkoutRecord`에 `field: Field?` 관계를 추가한다 (옵셔널 — 기존에 이미 저장된 기록은 운동장이 연결 안 되어 있을 수 있음).

## 1. 운동장 등록 (iPhone, 새 화면)

- 위성 지도(`Map`에 `.imagery` 스타일 적용) 위에 탭하면 핀이 순서대로 최대 4개까지 찍힌다.
- 이미 찍힌 핀은 드래그로 위치를 조정할 수 있다 (`MapCircle`/`Annotation` + `.onLongPressGesture` 또는 `MapCameraPosition` 유지하며 좌표 업데이트).
- 4개를 다 찍으면 이름 입력 필드 + "저장" 버튼이 나타나고, 저장하면 `Field`로 SwiftData에 들어간다.
- 운동장 목록 화면(새 화면)에서 등록된 `Field`들을 보고, "새 운동장 추가"로 위 등록 화면에 진입할 수 있다.

## 2. 좌표 변환 — `FieldCoordinateMapper`

뷰/SwiftData와 분리된 순수 로직 타입.

```swift
struct FieldCoordinateMapper {
    private let topLeft: CLLocationCoordinate2D
    private let topRight: CLLocationCoordinate2D
    private let bottomLeft: CLLocationCoordinate2D
    private let bottomRight: CLLocationCoordinate2D

    init(field: Field) {
        // cornerA~D를 위도/경도 기준으로 정렬해 topLeft/topRight/bottomLeft/bottomRight를 결정
    }

    /// 위도/경도 → 운동장 내 정규화 좌표 (0...1, 0...1). 사각형 밖이면 0...1 범위를 벗어난 값이 나올 수 있다(클램프하지 않음 — 호출부에서 필요하면 클램프).
    func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        // bilinear 사각형 보간의 역변환(뉴턴-랩슨 반복)으로 (u, v) 계산
    }
}
```

- bilinear 사각형 보간: 정방향(= u,v → 위도/경도)은 닫힌 식으로 바로 계산되지만, 우리가 필요한 건 역방향(위도/경도 → u,v)이라 뉴턴-랩슨 몇 회 반복으로 근사한다. GPS 핀 오차가 있는 실제 사각형에서도 안정적으로 동작한다.
- 이 타입은 SwiftUI/SwiftData에 의존하지 않는 순수 Swift 구조체로 두어 독립적으로 재사용/검증 가능하게 한다.

## 3. 운동장 연결

- `WorkoutDetailView`에 "운동장 선택" 버튼을 추가한다. 누르면 등록된 `Field` 목록이 뜨고, 고르면 `record.field`에 연결 후 저장한다.
- `field`가 연결되지 않은 기록은 히트맵 섹션 대신 "운동장을 선택해주세요" + 선택 버튼만 보여준다.

## 4. 히트맵 렌더링

- `fieldCanvas` 스타일을 그대로 따른다: `Canvas`, `aspectRatio(105.0/68.0, contentMode: .fit)`, 검은 배경, 흰 테두리.
- 렌더링 로직은 프로토콜로 분리해 알고리즘을 나중에 교체할 수 있게 한다:

```swift
protocol HeatmapRenderer {
    func render(in context: inout GraphicsContext, size: CGSize, normalizedPoints: [CGPoint])
}
```

- 1차 구현은 `GridDensityHeatmapRenderer`: 정규화 좌표(0~1, 0~1) 평면을 N×M 그리드로 나눠 셀마다 포인트 개수를 세고, 밀도에 따라 불투명도를 다르게 한 사각형을 그린다. 그리드 크기(N, M)는 상수로 빼서 나중에 쉽게 바꿀 수 있게 한다.
- `FieldHeatmapView`가 `record.points`를 `FieldCoordinateMapper`로 정규화한 뒤 `HeatmapRenderer`에 넘겨 그린다.

## 개발 단계 (단계마다 빌드 확인 후 git commit)

1. `Field` SwiftData 모델 + `WorkoutRecord.field` 관계 추가
2. `FieldCoordinateMapper` (순수 로직, bilinear 보간 + 역변환)
3. 운동장 등록 화면 (위성 지도 + 핀 4개 + 이름 저장) + 운동장 목록 화면
4. `WorkoutDetailView`에 운동장 선택 UI 추가
5. `HeatmapRenderer` 프로토콜 + `GridDensityHeatmapRenderer` 기본 구현
6. `FieldHeatmapView` (fieldCanvas 스타일) + `WorkoutDetailView`에 통합

## 범위 밖 (Out of scope)

- 공격 방향(터치라인/골라인 방향, 기간별 좌우 반전)은 이번 범위에 포함하지 않는다.
- 구간 재생 슬라이더와 히트맵을 연동하는 것(재생 중 히트맵도 같이 필터링)은 이번 범위에 포함하지 않는다 — 전체 경로 기준 히트맵만 그린다.
