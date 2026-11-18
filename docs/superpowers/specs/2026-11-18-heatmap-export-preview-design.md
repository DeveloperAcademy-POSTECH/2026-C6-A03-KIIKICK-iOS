# 히트맵 내보내기 검증 뷰 Design

> 이슈 #102 (시연용 앱 구현)과는 직접 연관 없는 임시 개발 도구. GK를 제외한 9개 포지션의
> 목업 히트맵을 한 화면에서 훑어보고, 고해상도 PNG로 사진앱에 저장해 확대 시 품질을
> 확인하기 위한 검증 뷰.

## Overview

`MockHeatmapAnchorPreviewView`와 같은 "임시 검증 화면" 계열에 새 화면을 하나 추가한다.
GK를 제외한 9개 포지션(lw, st, rw, lm, cm, rm, lb, cb, rb) 각각의 목업 히트맵을 그리드로
미리 보고, 하나를 탭해 들어가서 저장 버튼으로 고해상도 PNG를 사진앱에 저장한다.

## 배경 / 동기

- `MockHeatmapPosition`은 손흥민/이강인/김민재 3개 프로필(lw/rm/cb)만 다루고,
  `MockHeatmapGenerator.anchors(for:)`도 7개 포지션만 처리한다(`rw`, `lb` 없음).
  히트맵 렌더링이 모든 포지션에서 잘 보이는지 확인하려면 나머지도 필요하다.
- 공유 이미지 저장(`ShareImageView`)은 이미 "진짜 벡터는 사진앱에 못 들어간다"는 제약 위에서
  PNG+`PHPhotoLibrary` 패턴을 쓰고 있다. 이번에도 같은 제약이라 같은 패턴을 재사용한다.
- RootView를 디버그 빌드에서 임시 화면으로 바꿔치기하는 패턴은 이번이 처음이 아니다
  (`fe24fe2` → `d75816f`로 되돌린 전례). 같은 패턴을 재사용하면 나중에 되돌리기도 쉽다.

## 1. 목업 데이터 확장 — `MockHeatmapGenerator.swift`

### 1-1. `anchors(for:)`에 `rw`, `lb` 추가

기존 코드에 이미 좌우 대칭 규칙이 있다: `lm`/`rm`을 비교하면 x(공격 방향)는 동일하고
y는 `1 - y`로 뒤집힌다. 이 규칙을 그대로 적용한다.

- `rw` = `lw`의 y를 `1 - y`로 미러
- `lb` = `rb`의 y를 `1 - y`로 미러

### 1-2. 샘플 포인트 생성 함수 추가

```swift
static func makeSamplePoints(seed: Int, position: Position) -> [MockHeatmapPoint]
```

- GK는 호출하지 않는다(그리드에서 제외).
- 포지션별 기본 스탯(속도·심박·노이즈)은 역할 계열로 묶어 기존 3개 프로필 중 하나를 베이스로 쓴다:
  - 공격 계열(`lw`, `st`, `rw`) → `profiles[0]` (손흥민)
  - 미드필더 계열(`lm`, `cm`, `rm`) → `profiles[1]` (이강인)
  - 수비 계열(`lb`, `cb`, `rb`) → `profiles[2]` (김민재)
- 앵커는 기존 `profileForQuarter(_:heatmapPosition:)`로 덮어써서 요청한 포지션 것을 쓴다
  (3쿼터 "의도적 오류" 시나리오에서 이미 쓰는 메커니즘 재사용).
- 쿼터 1개 분량만 생성한다(`makePoints` 1회 호출). 이벤트(`makeEvents`)는 이 화면에서
  쓰지 않으므로 호출하지 않는다.

## 2. 새 임시 뷰 — `HeatmapExportPreviewView.swift`

`Features/View/` 아래, `MockHeatmapAnchorPreviewView`와 동일한 위치·주석 관례
("앱의 일반 플로우에는 연결하지 않고, 아래 #Preview에서만 사용" 문구 대신 아래
§3에 쓰인 디버그 루트 연결을 명시)로 추가한다.

### 2-1. 그리드 화면

- `LazyVGrid` 2열. `Position.allCases`에서 `.gk`를 제외한 9개 각각에 대해:
  - 포지션 라벨(`.uppercased`, 예: `LW`, `ST`)
  - `FieldCanvasView` + `GridDensityHeatmapRenderer`로 그린 작은 썸네일
    (`MockHeatmapAnchorPreviewView`의 카드 레이아웃 재사용)
  - 셀 전체가 `NavigationLink`로 상세 화면 진입
- seed는 고정값(102) 사용.

### 2-2. 상세 화면

- 같은 히트맵을 크게 표시.
- "저장" 버튼 1개, `ShareImageView.save()`와 동일한 패턴:
  1. `ImageRenderer(content:)`로 캡처
  2. `renderer.scale`은 디바이스 스케일이 아니라 고정된 높은 값(8)으로 설정 —
     시뮬레이터에서도 항상 큰 PNG가 나오게 한다. `renderer.isOpaque = false`.
  3. `uiImage.pngData()` → `PHPhotoLibrary.requestAuthorization(.addOnly)` →
     `PHAssetCreationRequest.forAsset()` + `addResource(.photo, data:)`
  4. 상태(`idle`/`saving`/`success`/`failure(String)`) 텍스트로 결과 표시.

## 3. 진입 경로 — `RootView.swift`

```swift
var body: some View {
    #if DEBUG
    HeatmapExportPreviewView()
    #else
    routedContent
        .animation(.default, value: router.flow)
        .dismissKeyboardOnTap()
        .onAppear { ... }
    #endif
}

@ViewBuilder
private var routedContent: some View { /* 기존 switch router.flow 그대로 */ }
```

`fe24fe2`와 동일 구조. 되돌릴 때는 `d75816f`처럼 `#if DEBUG`/`#else`/`#endif`와
`HeatmapExportPreviewView()` 줄만 지우면 끝난다.

## 범위 밖 (Out of scope)

- 진짜 벡터(PDF) 내보내기 — 사용자가 PNG+사진앱 방식을 선택했으므로 보류.
- GK 포지션 — 히트맵 생성 대상에서 제외(요청 범위).
- 이 화면을 실제 앱 플로우(디버그 메뉴 등)에 영구적으로 연결하는 것 — 임시 검증 전용.

## 관련

- 이슈 #102 (시연용 앱 구현) — 작업 중인 브랜치/워크트리는 공유하지만 이슈 자체와는 무관.
- `MockHeatmapAnchorPreviewView` — 같은 계열의 선행 임시 검증 화면.
- `ShareImageView` / `ShareCardView` — PNG+`PHPhotoLibrary` 저장 패턴의 출처.
