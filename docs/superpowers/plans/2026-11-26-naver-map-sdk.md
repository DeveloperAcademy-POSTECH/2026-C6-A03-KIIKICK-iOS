# Naver Map SDK 전환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `FieldCreationView`(인터랙티브 핀 찍기)와 `FieldThumbnailView`/`TrackingSatelliteDebugView`(위성 스냅샷)에서 Apple MapKit을 네이버 지도 SDK로 교체한다.

**Architecture:** `NMFMapView`(UIKit)를 `UIViewRepresentable`로 감싼 `NaverMapView` 컴포넌트가 인터랙티브 지도를 대체하고, 화면 밖 `NMFMapView`를 렌더링-완료 콜백 후 비트맵으로 캡처하는 `NaverMapSnapshotter`가 `MKMapSnapshotter`를 대체한다. 기존 SwiftUI 상태 모델(`rawPinCoordinates`, `guidanceText` 등)은 그대로 유지하고 지도 구현체만 교체한다.

**Tech Stack:** Swift, SwiftUI, UIKit(`UIViewRepresentable`), Naver Maps iOS SDK (`NMapsMap` via SPM `https://github.com/navermaps/SPM-NMapsMap`, 버전 3.24.1+)

## Global Constraints

- Client ID만 앱에 저장한다 (`cd77jxsaf9`). **Client Secret은 어떤 파일에도 쓰지 않는다** — 지도 SDK가 쓰지 않고, 서버사이드 Open API 전용이다.
- 자격증명은 `KIIKICK/Config.xcconfig`(gitignore 대상, 이미 `NAVER_MAP_CLIENT_ID = cd77jxsaf9` 추가됨) → `Info.plist`의 `NMFNcpKeyId` 키 → `$(NAVER_MAP_CLIENT_ID)` 매크로 패턴을 따른다. `BASE_URL`과 동일한 패턴.
- `NMFMarker`엔 네이티브 draggable이 없다. `UIPanGestureRecognizer` + `mapView.projection`으로 수동 구현한다 (MapKit 시절에도 수동 드래그였으므로 새로운 제약 아님).
- `NMFMapView`엔 `MKMapSnapshotter` 같은 오프스크린 스냅샷 API가 없다. `NMFMapViewRenderDelegate.mapView(_:mapViewDidFinishRenderingFrame:fully:stable:)`로 `fully && stable`을 기다렸다가 `UIGraphicsImageRenderer`/`drawHierarchy`로 직접 캡처한다.
- 지도 렌더링은 자동화 테스트 전례가 없는 영역이다 (MapKit 시절에도 없었음). "테스트"는 빌드 통과 + 시뮬레이터 수동 확인으로 대체한다.
- 커밋은 한국어, `[tag] 제목` 형식 (`rules/GIT.md`). 이 작업은 `tag=feat`.

---

### Task 1: 죽은 MapKit 코드 제거 (`WorkoutDetailView`)

**Files:**
- Modify: `KIIKICK/KIIKICK/Features/View/WorkoutDetailView.swift`

**Interfaces:** 없음 (다른 태스크와 독립적인 정리 작업)

- [ ] **Step 1: `import MapKit`과 미사용 `region` 계산 제거**

`KIIKICK/KIIKICK/Features/View/WorkoutDetailView.swift`에서:
- 7번째 줄 `import MapKit` 삭제
- 87~103번째 줄의 `private var region: MKCoordinateRegion { ... }` 전체 삭제 (호출부가 프로젝트 전체에 없음을 `grep -rn "\.region\b" KIIKICK/KIIKICK/Features/View/WorkoutDetailView.swift`로 재확인했음)

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED (이 파일은 아무 곳에서도 호출되지 않으므로 컴파일 에러가 나면 다른 원인이다)

- [ ] **Step 3: 커밋**

```bash
git add "KIIKICK/KIIKICK/Features/View/WorkoutDetailView.swift"
git commit -m "[refactor] WorkoutDetailView의 죽은 MapKit 코드 제거"
```

---

### Task 2: Naver Maps SDK 의존성 추가 + 인증 연결

**Files:**
- Modify: `KIIKICK/KIIKICK.xcodeproj/project.pbxproj`
- Modify: `KIIKICK/KIIKICK/Info.plist`
- (이미 완료) `KIIKICK/Config.xcconfig`에 `NAVER_MAP_CLIENT_ID = cd77jxsaf9` 존재, `Config.xcconfig.example`에 placeholder 존재

**Interfaces:**
- Produces: `NMFNcpKeyId` Info.plist 키 (이후 태스크의 지도 컴포넌트들이 이 키로 자동 인증됨 — 별도 코드 호출 불필요)

- [ ] **Step 1: SPM 패키지 레퍼런스 추가**

`project.pbxproj`의 기존 `lottie-ios` 블록(576~585번째 줄)을 참고해 같은 섹션에 두 개의 `XCRemoteSwiftPackageReference`를 추가한다 (`NMapsMap`은 `NMapsGeometry`에 의존하고, 두 모듈 심볼을 앱 코드에서 직접 쓰므로 둘 다 명시적으로 추가):

`/* Begin XCRemoteSwiftPackageReference section */` 안, 기존 lottie-ios 블록 뒤에 추가:
```
		A1B2C3D4E5F6071829384756 /* XCRemoteSwiftPackageReference "SPM-NMapsMap" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/navermaps/SPM-NMapsMap";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 3.24.1;
			};
		};
		B2C3D4E5F60718293847566A /* XCRemoteSwiftPackageReference "SPM-NMapsGeometry" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/navermaps/SPM-NMapsGeometry";
			requirement = {
				kind = upToNextMajorVersion;
				minimumVersion = 1.0.2;
			};
		};
```

`/* Begin XCSwiftPackageProductDependency section */` 안, 기존 Lottie 블록 뒤에 추가:
```
		C3D4E5F60718293847566A7B /* NMapsMap */ = {
			isa = XCSwiftPackageProductDependency;
			package = A1B2C3D4E5F6071829384756 /* XCRemoteSwiftPackageReference "SPM-NMapsMap" */;
			productName = NMapsMap;
		};
		D4E5F60718293847566A7B8C /* NMapsGeometry */ = {
			isa = XCSwiftPackageProductDependency;
			package = B2C3D4E5F60718293847566A /* XCRemoteSwiftPackageReference "SPM-NMapsGeometry" */;
			productName = NMapsGeometry;
		};
```

`PBXProject`의 `packageReferences` 배열(193~195번째 줄)에 추가:
```
			packageReferences = (
				95C5C117CF6C4A90957F9490 /* XCRemoteSwiftPackageReference "lottie-ios" */,
				A1B2C3D4E5F6071829384756 /* XCRemoteSwiftPackageReference "SPM-NMapsMap" */,
				B2C3D4E5F60718293847566A /* XCRemoteSwiftPackageReference "SPM-NMapsGeometry" */,
			);
```

`KIIKICK` 타겟(`000000000000000100000000`)의 `packageProductDependencies`(140~142번째 줄)에 추가:
```
			packageProductDependencies = (
				6F5F3C9B255A403EB94E89C5 /* Lottie */,
				C3D4E5F60718293847566A7B /* NMapsMap */,
				D4E5F60718293847566A7B8C /* NMapsGeometry */,
			);
```

`PBXBuildFile` 섹션(9~12번째 줄)에 "in Frameworks" 엔트리 추가:
```
		E5F60718293847566A7B8C9D /* NMapsMap in Frameworks */ = {isa = PBXBuildFile; productRef = C3D4E5F60718293847566A7B /* NMapsMap */; };
		F60718293847566A7B8C9DE0 /* NMapsGeometry in Frameworks */ = {isa = PBXBuildFile; productRef = D4E5F60718293847566A7B8C /* NMapsGeometry */; };
```

`KIIKICK` 타겟의 `PBXFrameworksBuildPhase`(`000000000000000130000000`, 84~89번째 줄) `files`에 추가:
```
			files = (
				C62ADE70F05840628372BF03 /* Lottie in Frameworks */,
				E5F60718293847566A7B8C9D /* NMapsMap in Frameworks */,
				F60718293847566A7B8C9DE0 /* NMapsGeometry in Frameworks */,
			);
```

- [ ] **Step 2: 패키지 해석 확인**

Run: `cd "KIIKICK" && xcodebuild -resolvePackageDependencies -project KIIKICK.xcodeproj -scheme KIIKICK`
Expected: `Resolved source packages`에 `NMapsMap`과 `NMapsGeometry`가 나열됨, 에러 없음.

**만약 실패하면** (pbxproj 수동 편집은 구조가 깨지기 쉽다): Xcode를 열어 File ▸ Add Package Dependencies에 `https://github.com/navermaps/SPM-NMapsMap`을 입력하고 "Up to Next Major 3.24.1"로 `KIIKICK` 타겟에 추가 — 이때 `NMapsMap`과 `NMapsGeometry` 두 프로덕트를 모두 체크한다. Xcode가 pbxproj를 직접 재작성하므로 위 수동 블록은 버리고 이 방법으로 대체한다.

- [ ] **Step 3: Info.plist에 Client ID 키 추가**

`KIIKICK/KIIKICK/Info.plist`의 `<dict>` 안, `BaseURL` 키 뒤에 추가:
```xml
	<key>NMFNcpKeyId</key>
	<string>$(NAVER_MAP_CLIENT_ID)</string>
```

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 커밋**

```bash
git add "KIIKICK/KIIKICK.xcodeproj/project.pbxproj" "KIIKICK/KIIKICK/Info.plist"
git commit -m "[setting] 네이버 지도 SDK 의존성 및 Client ID 연결"
```

---

### Task 3: `NaverMapSnapshotter` 공용 헬퍼

**Files:**
- Create: `KIIKICK/KIIKICK/Features/Components/NaverMapSnapshotter.swift`

**Interfaces:**
- Consumes: `Task 2`에서 연결된 `NMFNcpKeyId` (앱 전역 인증, 별도 호출 불필요), `import NMapsMap`, `import NMapsGeometry`
- Produces: `NaverMapSnapshotter.renderSnapshot(coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage?` — `coordinates`가 비어있으면 `nil`. 4개일 때만 폴리곤을 그리고, 그 외 개수면 폴리곤 없이 bounds만 맞춘 스냅샷을 반환한다 (디버그 뷰는 임의 개수의 GPS 포인트를 넘기므로).

- [ ] **Step 1: 헬퍼 작성**

```swift
//
//  NaverMapSnapshotter.swift
//  KIIKICK
//
//  MKMapSnapshotter를 대체한다. NMFMapView엔 오프스크린 스냅샷 API가 없어서,
//  화면 밖에 NMFMapView를 띄우고 NMFMapViewRenderDelegate로 타일 로딩 완료를
//  감지한 뒤 뷰 자체를 비트맵으로 캡처한다.
//

import CoreLocation
import NMapsGeometry
import NMapsMap
import UIKit

enum NaverMapSnapshotter {

    @MainActor
    static func renderSnapshot(for coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        guard !coordinates.isEmpty else { return nil }

        let mapView = NMFMapView(frame: CGRect(origin: .zero, size: size))
        mapView.mapType = .satellite
        mapView.isNightModeEnabled = false
        mapView.minZoomLevel = 0
        mapView.maxZoomLevel = 21

        let latLngs = coordinates.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        let bounds = NMGLatLngBounds(latLngs: latLngs)
        let padding = max(size.width, size.height) * 0.18
        mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: padding))

        guard let image = await waitForRenderedImage(mapView: mapView, size: size) else { return nil }

        guard coordinates.count == 4 else { return image }

        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(at: .zero)

            let points = coordinates.map { mapView.projection.point(from: NMGLatLng(lat: $0.latitude, lng: $0.longitude)) }
            guard let first = points.first else { return }
            let path = UIBezierPath()
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.close()

            UIColor.white.withAlphaComponent(0.2).setFill()
            path.fill()
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    @MainActor
    private static func waitForRenderedImage(mapView: NMFMapView, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let observer = RenderCompletionObserver { [weak mapView] in
                guard let mapView else {
                    continuation.resume(returning: nil)
                    return
                }
                let image = UIGraphicsImageRenderer(size: size).image { _ in
                    mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
                }
                continuation.resume(returning: image)
            }
            mapView.addCameraDelegate(delegate: observer)
            observer.attach(to: mapView)
        }
    }
}

/// NMFMapViewRenderDelegate는 프레임마다 호출되므로, fully && stable이 되는
/// 첫 프레임에서 한 번만 콜백을 실행하고 스스로 떼어낸다.
private final class RenderCompletionObserver: NSObject, NMFMapViewRenderDelegate {
    private let onReady: () -> Void
    private var hasFired = false
    private weak var mapView: NMFMapView?

    init(onReady: @escaping () -> Void) {
        self.onReady = onReady
    }

    func attach(to mapView: NMFMapView) {
        self.mapView = mapView
        mapView.addRenderObserver(self)
    }

    func mapView(_ mapView: NMFMapView, mapViewDidFinishRenderingFrame fully: Bool, stable: Bool) {
        guard fully, stable, !hasFired else { return }
        hasFired = true
        mapView.removeRenderObserver(self)
        onReady()
    }
}
```

> **참고:** `addCameraDelegate`/`addRenderObserver`/`removeRenderObserver` 정확한 API 이름은 SDK 버전에 따라 `mapView.addCameraDelegate(delegate:)` 대신 `touchDelegate`/`renderDelegate` 프로퍼티 직접 할당일 수 있다. Task 2에서 패키지가 실제로 추가된 뒤, Xcode 자동완성으로 `NMFMapView`의 delegate 등록 방식(프로퍼티 할당 vs observer 배열)을 확인해 이 블록을 맞춘다. 핵심 로직(화면 밖 뷰 생성 → bounds 맞추기 → `fully && stable` 대기 → `drawHierarchy` 캡처)은 변하지 않는다.

- [ ] **Step 2: 빌드 확인 (컴파일만 — 아직 호출부 없음)**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED. 실패하면 delegate 등록 API 이름을 Xcode 자동완성/`NMFMapView.h`로 확인해 수정.

- [ ] **Step 3: 커밋**

```bash
git add "KIIKICK/KIIKICK/Features/Components/NaverMapSnapshotter.swift"
git commit -m "[feat] 네이버 지도 오프스크린 스냅샷 헬퍼 추가"
```

---

### Task 4: `FieldThumbnailView` / `TrackingSatelliteDebugView` 마이그레이션

**Files:**
- Modify: `KIIKICK/KIIKICK/Features/Components/FieldThumbnailView.swift`
- Modify: `KIIKICK/KIIKICK/Features/Components/TrackingSatelliteDebugView.swift`

**Interfaces:**
- Consumes: `NaverMapSnapshotter.renderSnapshot(for:size:) async -> UIImage?` (Task 3)

- [ ] **Step 1: `FieldThumbnailView` 교체**

`KIIKICK/KIIKICK/Features/Components/FieldThumbnailView.swift`에서 `import MapKit` 삭제, 12~13번째 줄을 `import CoreLocation` 하나만 남긴다. `renderSnapshot` static 함수(45~84번째 줄) 전체를 삭제하고 `.task(id: coordinates)` 블록을 아래로 바꾼다:

```swift
        .task(id: coordinates) {
            snapshotImage = await NaverMapSnapshotter.renderSnapshot(for: coordinates, size: Self.size)
        }
```

- [ ] **Step 2: `TrackingSatelliteDebugView` 교체**

`KIIKICK/KIIKICK/Features/Components/TrackingSatelliteDebugView.swift`의 `loadSnapshot(size:)`(70~114번째 줄)에서 `MKMapSnapshotter` 관련 코드를 지우고 `NaverMapSnapshotter`로 이미지만 받아온 뒤, 기존 `projectedPoints`/`projectedCorners` 투영 로직은 `NMFMapView`를 직접 들고 있지 않으므로 좌표를 직접 수학적으로 투영하는 대신, 이 디버그 뷰는 **원본 GPS와 정규화 축 비교가 목적**이라 스냅샷 이미지 위에 점을 찍는 투영 좌표가 필요하다. 이를 위해 `NaverMapSnapshotter`에 투영 좌표도 함께 돌려주는 오버로드를 추가한다:

`NaverMapSnapshotter.swift`에 추가:
```swift
    /// `cameraBounds`로 카메라를 맞추고, `projecting`에 있는 모든 좌표의 화면 투영점을
    /// 같은 순서로 돌려준다 (오프스크린 렌더를 1회만 수행하기 위해 분리했다).
    @MainActor
    static func renderSnapshotWithProjection(
        cameraBounds: [CLLocationCoordinate2D],
        projecting coordinates: [CLLocationCoordinate2D],
        size: CGSize
    ) async -> (image: UIImage, points: [CGPoint])? {
        let mapView = NMFMapView(frame: CGRect(origin: .zero, size: size))
        mapView.mapType = .satellite

        let latLngs = cameraBounds.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        guard !latLngs.isEmpty else { return nil }
        let bounds = NMGLatLngBounds(latLngs: latLngs)
        mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: max(size.width, size.height) * 0.18))

        guard let image = await waitForRenderedImage(mapView: mapView, size: size) else { return nil }
        let points = coordinates.map { mapView.projection.point(from: NMGLatLng(lat: $0.latitude, lng: $0.longitude)) }
        return (image, points)
    }
```

`TrackingSatelliteDebugView.swift`의 `loadSnapshot(size:)`를 아래로 교체:
```swift
    @MainActor
    private func loadSnapshot(size: CGSize) async {
        guard size.width > 1, size.height > 1 else { return }
        image = nil
        errorMessage = nil
        let coordinates = points.compactMap { point -> CLLocationCoordinate2D? in
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
        }
        let corners = field.map { FieldCoordinateMapper(field: $0).orderedCorners } ?? []
        let bounds = corners.isEmpty ? coordinates : corners
        guard !bounds.isEmpty else {
            errorMessage = "표시할 좌표가 없어요"
            return
        }
        // bounds(코너 우선, 없으면 GPS 포인트)로 카메라를 맞추고, 투영은 코너 +
        // GPS 포인트를 한 번에 요청해 오프스크린 렌더를 한 번만 수행한다.
        let allPoints = corners + coordinates
        guard let result = await NaverMapSnapshotter.renderSnapshotWithProjection(
            cameraBounds: bounds,
            projecting: allPoints,
            size: size
        ) else {
            errorMessage = "위성사진을 불러오지 못했어요"
            return
        }
        image = result.image
        let cornerCount = corners.count
        projectedCorners = cornerCount == 4 ? Array(result.points.prefix(4)) : []
        projectedPoints = Array(result.points.suffix(coordinates.count)).filter {
            $0.x.isFinite && $0.y.isFinite && CGRect(origin: .zero, size: size).contains($0)
        }
    }
```

파일 상단 `import MapKit`을 `import CoreLocation`으로 바꾼다. `snapshotter: MKMapSnapshotter?` state와 `onDisappear { snapshotter?.cancel() }`는 더 이상 필요 없으므로 삭제.

- [ ] **Step 3: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 시뮬레이터 수동 확인**

시뮬레이터에서 경기장 등록 플로우로 이동해 `FieldNamingView`의 썸네일(위성 이미지 + 흰 폴리곤 경계선)이 보이는지 확인. DEBUG 빌드에서 `TrackingSatelliteDebugView`가 기존과 동일하게 GPS 점/경계선을 그리는지 확인.

- [ ] **Step 5: 커밋**

```bash
git add "KIIKICK/KIIKICK/Features/Components/FieldThumbnailView.swift" "KIIKICK/KIIKICK/Features/Components/TrackingSatelliteDebugView.swift" "KIIKICK/KIIKICK/Features/Components/NaverMapSnapshotter.swift"
git commit -m "[feat] FieldThumbnailView/디버그 뷰를 네이버 지도 스냅샷으로 전환"
```

---

### Task 5: `NaverMapView` 인터랙티브 컴포넌트

**Files:**
- Create: `KIIKICK/KIIKICK/Features/Components/NaverMapView.swift`

**Interfaces:**
- Produces:
  - `struct NaverMapView: UIViewRepresentable`
  - `init(pins: Binding<[CLLocationCoordinate2D]>, userTrackingEnabled: Bool, onTapEmptyMap: @escaping (CLLocationCoordinate2D) -> Void)`
  - `func moveCamera(to coordinates: [CLLocationCoordinate2D])` 는 Coordinator가 바인딩 변화에 반응해서 자동 처리 (별도 public API 불필요 — `updateUIView`에서 핀 개수가 바뀔 때 1회성으로 bounds-fit)
  - 내부 `Coordinator`가 `NMFMapViewTouchDelegate`, `UIGestureRecognizerDelegate`를 구현

- [ ] **Step 1: 컴포넌트 작성**

```swift
//
//  NaverMapView.swift
//  KIIKICK
//
//  FieldCreationView의 "꼭짓점 4개 찍기" 지도를 담당한다. NMFMarker엔 네이티브
//  draggable이 없어서(MapKit의 Annotation도 마찬가지였다) UIPanGestureRecognizer로
//  수동 드래그를 구현한다 — 터치 시작 지점과 각 마커의 화면좌표(projection)를 비교해
//  어떤 마커를 드래그하는지 판정한다.
//

import CoreLocation
import NMapsGeometry
import NMapsMap
import SwiftUI

struct NaverMapView: UIViewRepresentable {
    @Binding var pins: [CLLocationCoordinate2D]
    var draggingIndex: Binding<Int?>
    var onTapEmptyMap: (CLLocationCoordinate2D) -> Void
    var recenterTrigger: Bool

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        mapView.mapType = .satellite
        mapView.touchDelegate = context.coordinator
        mapView.positionMode = .direction

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        mapView.addGestureRecognizer(pan)

        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ mapView: NMFMapView, context: Context) {
        context.coordinator.sync(pins: pins, draggingIndex: draggingIndex.wrappedValue)

        if recenterTrigger != context.coordinator.lastRecenterTrigger {
            context.coordinator.lastRecenterTrigger = recenterTrigger
            mapView.moveCamera(NMFCameraUpdate(scrollTo: mapView.locationOverlay.location))
        } else if context.coordinator.shouldFitCamera(for: pins) {
            let bounds = NMGLatLngBounds(latLngs: pins.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
            mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: 60))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pins: $pins, draggingIndex: draggingIndex, onTapEmptyMap: onTapEmptyMap)
    }

    final class Coordinator: NSObject, NMFMapViewTouchDelegate, UIGestureRecognizerDelegate {
        private var pins: Binding<[CLLocationCoordinate2D]>
        private var draggingIndex: Binding<Int?>
        private let onTapEmptyMap: (CLLocationCoordinate2D) -> Void
        weak var mapView: NMFMapView?
        private var markers: [NMFMarker] = []
        private var polyline: NMFPolylineOverlay?
        private var lastPinCount = -1
        var lastRecenterTrigger = false
        private var draggingMarkerIndex: Int?

        init(
            pins: Binding<[CLLocationCoordinate2D]>,
            draggingIndex: Binding<Int?>,
            onTapEmptyMap: @escaping (CLLocationCoordinate2D) -> Void
        ) {
            self.pins = pins
            self.draggingIndex = draggingIndex
            self.onTapEmptyMap = onTapEmptyMap
        }

        func shouldFitCamera(for pins: [CLLocationCoordinate2D]) -> Bool {
            defer { lastPinCount = pins.count }
            return pins.count == 4 && lastPinCount != 4
        }

        /// 마커/폴리라인을 pins 배열과 동기화한다. SwiftUI의 선언적 모델을 NMFMapView의
        /// 명령형 오버레이 API로 매번 다시 그리지 않고 diff 없이 전체 재생성한다 —
        /// 핀 개수가 최대 4개뿐이라 성능 영향이 없다.
        func sync(pins newPins: [CLLocationCoordinate2D], draggingIndex: Int?) {
            markers.forEach { $0.mapView = nil }
            markers = newPins.enumerated().map { index, coordinate in
                let marker = NMFMarker(position: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude))
                marker.iconImage = NMFOverlayImage(image: pinImage(number: index + 1))
                marker.mapView = mapView
                return marker
            }

            polyline?.mapView = nil
            polyline = nil
            guard newPins.count >= 2 else { return }
            let closed = newPins.count == 4 ? newPins + [newPins[0]] : newPins
            let overlay = NMFPolylineOverlay(closed.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
            overlay.color = UIColor(Color.mint500).withAlphaComponent(0.8)
            overlay.width = 2
            overlay.mapView = mapView
            polyline = overlay
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let mapView else { return }
            let location = gesture.location(in: mapView)

            switch gesture.state {
            case .began:
                draggingMarkerIndex = markers.indices.min(by: {
                    distance(mapView.projection.point(from: markers[$0].position), location)
                        < distance(mapView.projection.point(from: markers[$1].position), location)
                }).flatMap { index in
                    distance(mapView.projection.point(from: markers[index].position), location) < 28 ? index : nil
                }
                if let draggingMarkerIndex {
                    draggingIndex.wrappedValue = draggingMarkerIndex
                }
            case .changed:
                guard let index = draggingMarkerIndex else { return }
                let latLng = mapView.projection.latlng(from: location)
                markers[index].position = latLng
                var updated = pins.wrappedValue
                updated[index] = CLLocationCoordinate2D(latitude: latLng.lat, longitude: latLng.lng)
                pins.wrappedValue = updated
                rebuildPolyline(from: updated)
            case .ended, .cancelled, .failed:
                draggingMarkerIndex = nil
                draggingIndex.wrappedValue = nil
            default:
                break
            }
        }

        private func rebuildPolyline(from coordinates: [CLLocationCoordinate2D]) {
            polyline?.mapView = nil
            guard coordinates.count >= 2 else { polyline = nil; return }
            let closed = coordinates.count == 4 ? coordinates + [coordinates[0]] : coordinates
            let overlay = NMFPolylineOverlay(closed.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
            overlay.color = UIColor(Color.mint500).withAlphaComponent(0.8)
            overlay.width = 2
            overlay.mapView = mapView
            polyline = overlay
        }

        private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot(a.x - b.x, a.y - b.y)
        }

        private func pinImage(number: Int) -> UIImage {
            let size = CGSize(width: 44, height: 44)
            return UIGraphicsImageRenderer(size: size).image { ctx in
                let rect = CGRect(x: 8, y: 8, width: 28, height: 28)
                UIColor(Color.gray950).setFill()
                UIBezierPath(ovalIn: rect).fill()
                UIColor(Color.mint500).setStroke()
                let stroke = UIBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5))
                stroke.lineWidth = 3
                stroke.stroke()
                let text = "\(number)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor(Color.mint500),
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                ]
                let textSize = text.size(withAttributes: attrs)
                text.draw(
                    at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2),
                    withAttributes: attrs
                )
            }
        }

        // MARK: - NMFMapViewTouchDelegate

        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            guard draggingMarkerIndex == nil else { return }
            onTapEmptyMap(CLLocationCoordinate2D(latitude: latlng.lat, longitude: latlng.lng))
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // 마커를 드래그 중일 땐 지도 자체의 팬(이동)과 동시에 인식되면 안 된다.
            draggingMarkerIndex == nil
        }
    }
}
```

> **참고:** `mapView.locationOverlay`, `positionMode`, `didTapMap`의 정확한 파라미터 타입(`NMGLatLng` vs `Any!`)은 실제 SDK 헤더 기준으로 Xcode 자동완성에서 확인해 맞춘다. `UIColor(Color.mint500)` 변환이 프로젝트의 `Color` 확장(`DESIGN.md` 토큰)에서 바로 되는지도 빌드 시 확인.

- [ ] **Step 2: 빌드 확인 (컴파일만)**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 커밋**

```bash
git add "KIIKICK/KIIKICK/Features/Components/NaverMapView.swift"
git commit -m "[feat] 인터랙티브 네이버 지도 컴포넌트(NaverMapView) 추가"
```

---

### Task 6: `FieldCreationView` 마이그레이션

**Files:**
- Modify: `KIIKICK/KIIKICK/Features/View/FieldCreationView.swift`

**Interfaces:**
- Consumes: `NaverMapView(pins:draggingIndex:onTapEmptyMap:recenterTrigger:)` (Task 5)

- [ ] **Step 1: `Map { ... }` 블록을 `NaverMapView`로 교체**

`import MapKit`을 삭제하고 `import CoreLocation`만 남긴다. `@State private var cameraPosition: MapCameraPosition`과 `MapReader`/`Map` 블록(92~120번째 줄)을 제거하고, `body`의 `ZStack` 최상단을 아래로 교체:

```swift
    @State private var recenterTrigger = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NaverMapView(
                pins: $rawPinCoordinates,
                draggingIndex: $draggingIndex,
                onTapEmptyMap: { coordinate in
                    guard rawPinCoordinates.count < 4 else { return }
                    rawPinCoordinates.append(coordinate)
                },
                recenterTrigger: recenterTrigger
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                guidanceBanner
                    .padding(.top, 12)
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    if !rawPinCoordinates.isEmpty {
                        undoButton
                    }
                    Spacer()
                    myLocationButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 88)

            CtaView(
                text: editingField == nil ? "추가" : "다음",
                type: .primary,
                size: .large,
                isActive: rawPinCoordinates.count == 4
            ) {
                goNext = rawPinCoordinates.count == 4
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle(editingField == nil ? "경기장 등록" : "경기장 수정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .navigationDestination(isPresented: $goNext) {
            FieldNamingView(
                rawCoordinates: rawPinCoordinates,
                editingField: editingField,
                onFinish: onFinish,
                onFieldPrepared: onFieldPrepared,
                onFieldSaved: onFieldSaved,
                onFieldUpdated: onFieldUpdated
            )
        }
    }
```

`myLocationButton`의 액션을 `cameraPosition` 대신 `recenterTrigger.toggle()`로 바꾼다:
```swift
    private var myLocationButton: some View {
        Button {
            recenterTrigger.toggle()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18))
                .foregroundStyle(.gray50)
                .frame(width: 44, height: 44)
                .background(Color.gray900, in: Circle())
                .overlay(Circle().stroke(Color.gray700, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
```

`initialCameraPosition(for:)` static 함수는 `NaverMapView`의 `shouldFitCamera`가 대체하므로 삭제한다. `init`에서 `_cameraPosition = State(...)` 할당 줄도 삭제.

`pinDragGesture`/`pinHandle` 함수는 `NaverMapView.Coordinator`가 네이티브 마커로 대체했으므로 삭제한다.

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 시뮬레이터 수동 확인**

경기장 등록 플로우로 이동해:
- 빈 지도를 탭하면 순서대로 핀 1~4가 찍히는지
- 찍힌 핀을 드래그하면 위치가 갱신되고 점선 폴리곤이 따라오는지
- 4개를 다 찍으면 "추가" 버튼이 활성화되는지
- 위성 이미지가 표시되는지
- 내 위치 버튼이 동작하는지

- [ ] **Step 4: 커밋**

```bash
git add "KIIKICK/KIIKICK/Features/View/FieldCreationView.swift"
git commit -m "[feat] FieldCreationView를 네이버 지도로 전환"
```

---

### Task 7: 최종 점검

**Files:** 없음 (검증만)

- [ ] **Step 1: MapKit 잔존 여부 전체 스캔**

Run: `grep -rl "import MapKit" KIIKICK --include="*.swift"`
Expected: 결과 없음 (0 파일)

- [ ] **Step 2: 전체 빌드 (iOS + watchOS 스킴 둘 다)**

Run:
```bash
cd "KIIKICK" && xcodebuild build -project KIIKICK.xcodeproj -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -quiet
xcodebuild build -project KIIKICK.xcodeproj -scheme "KIIKICK Watch App Watch App" -destination 'generic/platform=watchOS Simulator' -quiet
```
Expected: 둘 다 BUILD SUCCEEDED (watchOS는 지도를 쓰지 않으므로 영향 없어야 함을 재확인)

- [ ] **Step 3: 수동 회귀 체크리스트**

- `FieldCreationView` 신규 등록 + 기존 경기장 수정(`editingField` 경로) 둘 다 확인
- `FieldNamingView` 썸네일
- DEBUG 빌드에서 `TrackingSatelliteDebugView`
- 경기장 목록에 저장된 경기장을 다시 열었을 때 좌표가 깨지지 않는지

- [ ] **Step 4: 최종 커밋 (필요시)**

남은 변경사항이 있다면:
```bash
git add -A
git commit -m "[fix] 네이버 지도 전환 최종 점검 수정"
```
