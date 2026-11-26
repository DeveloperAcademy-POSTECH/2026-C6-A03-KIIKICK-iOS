# Naver Map SDK 전환 설계 (#105)

## 배경

Apple Map(MapKit)의 위성 지도가 일부 지역에서 최신화되어 있지 않고, 아파트 단지 등 일부 건물이 수직이 아니라 기울어져 촬영되어 경기장 꼭짓점을 정확히 찍기 어려운 경우가 있다. 네이버 지도 SDK로 전환해 더 정확한 위성 이미지를 사용한다.

## 현황 조사

Apple Maps(MapKit) 렌더링을 실제로 사용하는 곳은 아래 3곳뿐이다 (`grep -rl "import MapKit"` + API 사용 확인):

1. **`FieldCreationView.swift`** — 경기장 꼭짓점 4개를 탭으로 찍는 인터랙티브 지도. `Map`, `MapReader`, `UserAnnotation`, `MapPolyline`, 커스텀 드래그(`Annotation` + `DragGesture`)를 쓴다.
2. **`FieldThumbnailView.swift`** — `MKMapSnapshotter`로 위성 스냅샷을 렌더링하고 그 위에 경계선 폴리곤을 겹쳐 그린다. `FieldNamingView`의 "선택된 경기장" 카드에서 쓴다.
3. **`TrackingSatelliteDebugView.swift`** (`#if DEBUG`) — 같은 `MKMapSnapshotter` 패턴으로 원본 GPS와 정규화 좌표를 비교하는 디버그 화면.

`WorkoutDetailView.swift`도 `import MapKit`이 있지만, 그 안의 `region: MKCoordinateRegion` 계산은 **어디서도 참조되지 않는 죽은 코드**이고 `WorkoutDetailView` 자체도 네비게이션 호출부가 없다 (`grep -rn "WorkoutDetailView("`가 정의부 외엔 0건). 전환 대상이 아니라 삭제 대상이다.

히트맵/트래킹 경로 시각화(`FieldHeatmapView`, `TrackingMapPager`, `FriendHeatmapView`, `SprintMapView`, `CardQuarterView` 등)는 MapKit이 아니라 `Canvas` + 자체 좌표 변환(`FieldCoordinateMapper`)으로 그려서 이번 전환과 무관하다.

## SDK 조사 결과 (navermaps 공식 문서 기준)

- SPM 패키지: `https://github.com/navermaps/SPM-NMapsMap`
- Client ID 등록: Info.plist `NMFNcpKeyId` 키 (또는 코드에서 `NMFAuthManager.shared().client = NMFNcpKeyClient(ncpKeyId:)`). **Client Secret은 SDK가 쓰지 않는다** — 서버사이드 Open API용이므로 앱에 넣지 않는다.
- 지도 뷰: `NMFMapView` (UIKit 뷰, SwiftUI에서는 `UIViewRepresentable`로 감싼다)
- 위성 지도: `mapView.mapType = .satellite` (또는 `.hybrid`)
- 탭 이벤트: `NMFMapViewTouchDelegate.mapView(_:didTapMap:point:)` — 위경도(`NMGLatLng`)와 화면 좌표를 동시에 준다
- 마커: `NMFMarker`, `position: NMGLatLng` 읽기/쓰기 가능. **`draggable` 속성은 없다** — MapKit도 네이티브 드래그가 없어서 지금 코드도 이미 수동 드래그(Annotation + DragGesture)를 구현하고 있으므로, 이 부분은 새로운 제약이 아니라 기존 패턴을 그대로 포팅하면 된다.
- 폴리라인: `NMFPolylineOverlay([NMGLatLng])` + `mapView.addOverlay(polyline)`, `.color`, `.width`, `.pattern`(점선)
- 스냅샷: **`MKMapSnapshotter` 같은 오프스크린 스냅샷 API가 없다.** 대신 `NMFMapViewRenderDelegate.mapView(_:mapViewDidFinishRenderingFrame:fully:stable:)`로 타일 로딩 완료(`fully && stable`)를 감지한 뒤, 화면 밖 `NMFMapView`를 `UIGraphicsImageRenderer`/`drawHierarchy`로 비트맵 캡처하는 방식으로 직접 구현해야 한다.

## 설계

### 1. 의존성 & 인증

- `KIIKICK.xcodeproj`에 `XCRemoteSwiftPackageReference`로 `https://github.com/navermaps/SPM-NMapsMap` 추가 (기존 `lottie-ios` 추가 방식과 동일)
- `Config.xcconfig`(gitignore 대상)에 `NAVER_MAP_CLIENT_ID = cd77jxsaf9` 추가, `Config.xcconfig.example`엔 placeholder만 커밋
- `Info.plist`에 `NMFNcpKeyId` 키로 `$(NAVER_MAP_CLIENT_ID)` 연결 — `BaseURL`/`BASE_URL`과 동일한 xcconfig→plist 패턴
- Client Secret은 코드/설정 어디에도 넣지 않는다

### 2. `NaverMapView` — `FieldCreationView`용 인터랙티브 지도 컴포넌트

새 파일 `KIIKICK/KIIKICK/Features/Components/NaverMapView.swift`에 `UIViewRepresentable` 래퍼를 만든다.

- **핀 추가**: `didTapMap:point:`에서 위경도를 바로 받아 `rawPinCoordinates`에 append (기존 `SpatialTapGesture` + `proxy.convert`보다 단순해짐)
- **핀 표시/드래그**: 좌표마다 `NMFMarker` 생성(번호 아이콘 포함). 드래그는 `UIPanGestureRecognizer`를 지도에 달고, `mapView.projection`으로 터치 화면좌표 ↔ 각 마커의 화면좌표를 비교해 어느 마커를 드래그 중인지 판정 → `NMGLatLng`로 역변환해 `marker.position` 갱신. 기존 "핀 하나 크기 뷰에 DragGesture"를 UIKit 레벨로 포팅하는 것과 동일한 아이디어.
- **점선 폴리곤**: 핀이 2개 이상이면 `NMFPolylineOverlay`로 갱신 (4개 다 찍히면 첫 점을 다시 붙여 폐곡선)
- **위성 지도**: `mapType = .satellite`
- **내 위치**: `NMFLocationOverlay` + 위치 권한은 기존 `CLLocationManager` 로직 유지
- **카메라**: 좌표 바운드에 맞춰 `NMFCameraUpdate`로 이동/줌 (기존 `MapCameraPosition` 초기화 로직을 좌표 bounds 기반으로 대응)
- SwiftUI 쪽 `FieldCreationView`는 가능한 한 현재 상태 모델(`rawPinCoordinates`, `draggingIndex`, `guidanceText`, undo/내 위치 버튼 등)을 그대로 유지하고, `Map { ... }` 블록만 `NaverMapView(...)`로 교체한다.

### 3. `NaverMapSnapshotter` — 정적 스냅샷 공용 헬퍼

새 파일 `KIIKICK/KIIKICK/Features/Components/NaverMapSnapshotter.swift`에 기존 `FieldThumbnailView.renderSnapshot`과 같은 모양(`[CLLocationCoordinate2D] + CGSize -> UIImage?`)의 `async` 함수를 만든다.

1. 화면 밖 `NMFMapView(frame: CGRect(origin: .zero, size: size))` 생성, `mapType = .satellite`, 좌표 bounds로 카메라 설정
2. `NMFMapViewRenderDelegate` 콜백에서 `fully && stable`이 되는 첫 프레임을 기다렸다가(continuation으로 1회만 resume) 캡처
3. `UIGraphicsImageRenderer`로 뷰 비트맵을 그리고, `mapView.projection.point(from:)`으로 꼭짓점을 투영해 기존과 동일한 흰색 반투명 폴리곤 오버레이를 그 위에 그린다
4. `FieldThumbnailView`와 `TrackingSatelliteDebugView`가 이 헬퍼를 공유한다 (후자는 DEBUG 전용이라 좌표 소스만 다름 — GPS 포인트 + 경기장 코너)

### 4. 정리

- `WorkoutDetailView.swift`: 미사용 `import MapKit`과 죽은 `region` 계산 제거 (호출부 없음 확인됨, 이 뷰 자체도 비활성 상태라 별도 risk 없음)
- 전환 완료 후 프로젝트 전체에 `import MapKit`이 남아있지 않은지 확인

### 5. 에러 처리

- 네트워크/타일 로딩 실패 시: `FieldThumbnailView`/스냅샷 헬퍼는 기존처럼 `nil` 반환 → placeholder(`ProgressView`/`Color.gray800`) 유지
- Client ID 미설정/인증 실패 시: SDK가 로그를 남기고 빈 지도를 보여주는 동작을 그대로 따른다 (앱 크래시 방지용 별도 가드 불필요 — SDK 자체가 graceful하게 처리)

### 6. 테스트 계획

지도 렌더링은 자동화 테스트 전례가 없는 영역(MapKit 시절에도 없었음)이라 수동 확인으로 검증한다:

- 시뮬레이터/실기기에서 `FieldCreationView`: 핀 4개 찍기 → 드래그로 위치 조정 → 점선 폴리곤이 좌표를 따라가는지 → 위성 이미지가 표시되는지
- `FieldNamingView`: 썸네일 스냅샷이 올바른 영역/폴리곤으로 렌더링되는지
- `TrackingSatelliteDebugView` (DEBUG 빌드): 기존과 동일하게 동작하는지
- 빌드가 시뮬레이터/실기기 타겟 모두에서 통과하는지 (watchOS 타겟은 지도를 쓰지 않으므로 영향 없음)

## 범위 밖

- 네이버 Open API(지오코딩, Static Map HTTP 등) 연동 — Client Secret이 필요한 영역이라 이번 전환 범위에서 제외. 필요해지면 백엔드 프록시를 거치는 별도 설계로 다룬다.
