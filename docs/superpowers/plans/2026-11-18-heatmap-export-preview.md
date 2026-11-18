# 히트맵 내보내기 검증 뷰 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GK를 제외한 9개 포지션의 목업 히트맵을 그리드로 미리 보고, 하나를 탭해 들어가서 고해상도 PNG로 사진앱에 저장하는 임시 검증 뷰를 만들고, 디버그 빌드에서 RootView 대신 바로 뜨게 연결한다.

**Architecture:** `MockHeatmapGenerator`에 포지션 하나짜리 샘플 포인트 생성 함수를 추가하고(앵커 좌우 대칭 2개 보강 포함), 그 위에 그리드+상세 2단 SwiftUI 뷰를 새로 만든다. 저장은 기존 `ShareImageView`의 `ImageRenderer` → PNG → `PHPhotoLibrary` 패턴을 그대로 재사용한다. 진입은 기존에 한 번 썼다가 되돌린 `RootView`의 `#if DEBUG` 전례(커밋 `fe24fe2` → `d75816f`)를 재사용한다.

**Tech Stack:** Swift / SwiftUI, Photos (PHPhotoLibrary), 기존 `FieldCanvasView`/`GridDensityHeatmapRenderer`/`FieldArtworkLayout`.

## Global Constraints

- 설계 문서: `docs/superpowers/specs/2026-11-18-heatmap-export-preview-design.md`. 이 플랜의 모든 작업은 그 문서 범위를 벗어나지 않는다.
- GK(`Position.gk`)는 히트맵 생성·그리드 대상에서 제외한다.
- 저장 형식은 PNG(사진앱)로 확정 — PDF/벡터 내보내기는 범위 밖.
- seed는 고정값 102 사용.
- 이 기능은 임시 검증용이다. 영구적인 디버그 메뉴 연결이나 실제 앱 플로우 통합은 하지 않는다.
- 테스트 방식: `MockHeatmapGenerator`는 `UserSession`(UIKit 의존)을 참조해서 `swiftc` 단독 컴파일 체크 스크립트 대상이 될 수 없고(`Tests/`, `scripts/validation/`의 기존 체크들도 UIKit 의존 파일은 전부 피해간다), 이 저장소에 `MockHeatmap*` 자동 테스트도 전례가 없다. 대신 `MockHeatmapAnchorPreviewView`가 이미 그렇듯, **이 뷰 자체가 검증 도구**다 — 각 작업의 "테스트"는 `xcodebuild build`로 컴파일 확인, 마지막 작업에서 시뮬레이터로 직접 띄워 눈으로 확인한다.

---

## Task 1: `MockHeatmapGenerator`에 rw/lb 앵커와 샘플 포인트 함수 추가

**Files:**
- Modify: `KIIKICK/KIIKICK/Data/MockHeatmapGenerator.swift:256-310` (`anchors(for:)`), 그리고 `make(seed:, position:)` 근처(145-182)에 새 함수 추가

**Interfaces:**
- Consumes: 없음 (기존 `Profile`, `profiles`, `profileForQuarter(_:heatmapPosition:)`, `makePoints(_:quarterNumber:start:random:)`, `defaultStartDate()`, `SeededRandom` — 모두 같은 파일 내부)
- Produces: `static func makeSamplePoints(seed: Int, position: Position) -> [MockHeatmapPoint]` — Task 2가 이 함수를 호출한다.

- [ ] **Step 1: `anchors(for:)`에 `.rw`, `.lb` case 추가**

`KIIKICK/KIIKICK/Data/MockHeatmapGenerator.swift`의 `private static func anchors(for position: Position) -> [Anchor]?` 안에 추가한다. 기존 `.lm`/`.rm` 쌍이 이미 "x(공격 방향)는 같고 y는 `1 - y`로 뒤집는다"는 좌우 대칭 규칙을 쓰고 있으므로 — `rw`는 `lw`를, `lb`는 `rb`를 그 규칙으로 미러한다. `.lw` case 바로 다음에 추가:

```swift
        case .rw:
            // lw를 y축 기준으로 미러(좌우 대칭 — lm/rm 쌍과 같은 규칙).
            return [
                Anchor(x: 0.56, y: 0.88, weight: 0.28),
                Anchor(x: 0.68, y: 0.80, weight: 0.42),
                Anchor(x: 0.86, y: 0.68, weight: 0.20),
                Anchor(x: 0.70, y: 0.74, weight: 0.10),
            ]
```

`.rb` case 바로 다음, `.rm` case 앞에 추가:

```swift
        case .lb:
            // rb를 y축 기준으로 미러.
            return [
                Anchor(x: 0.17, y: 0.34, weight: 0.30),
                Anchor(x: 0.16, y: 0.18, weight: 0.40),
                Anchor(x: 0.45, y: 0.10, weight: 0.20),
                Anchor(x: 0.40, y: 0.22, weight: 0.10),
            ]
```

- [ ] **Step 2: `makeSamplePoints(seed:position:)` 추가**

같은 파일, `make(seed:, position: MockHeatmapPosition, start:)` 함수(라인 164-182) 바로 다음에 추가:

```swift
    /// GK를 제외한 임의 포지션 1개의 샘플 히트맵 포인트(1쿼터분)를 만든다.
    /// 히트맵 내보내기 검증 화면에서만 사용한다.
    static func makeSamplePoints(seed: Int, position: Position) -> [MockHeatmapPoint] {
        let basis: Profile
        switch position {
        case .lw, .st, .rw:
            basis = profiles[0]
        case .lm, .cm, .rm:
            basis = profiles[1]
        case .lb, .cb, .rb, .gk:
            basis = profiles[2]
        }
        let profile = profileForQuarter(basis, heatmapPosition: position)
        let positionOffset = Position.allCases.firstIndex(of: position) ?? 0
        var random = SeededRandom(seed: seed + positionOffset * 10_007)
        return makePoints(profile, quarterNumber: 1, start: defaultStartDate(), random: &random)
    }
```

(`position.hashValue`가 아니라 `Position.allCases`의 고정된 선언 순서에서 나온 인덱스를 쓰는 이유: Swift의 문자열 `hashValue`는 프로세스마다 랜덤 시드가 섞여서 "같은 seed면 같은 결과"라는 이 목업 시스템의 전제가 깨진다.)

- [ ] **Step 3: 빌드로 컴파일 확인**

Run: `xcodebuild build -project "KIIKICK/KIIKICK.xcodeproj" -scheme KIIKICK -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add "KIIKICK/KIIKICK/Data/MockHeatmapGenerator.swift"
git commit -m "[feat] 히트맵 내보내기용 rw/lb 앵커와 단일 포지션 샘플 생성 추가"
```

---

## Task 2: `HeatmapExportPreviewView` 생성 (그리드 + 상세 + 저장)

**Files:**
- Create: `KIIKICK/KIIKICK/Features/View/HeatmapExportPreviewView.swift`

**Interfaces:**
- Consumes: `MockHeatmapGenerator.makeSamplePoints(seed:position:) -> [MockHeatmapPoint]` (Task 1), `Position` (`KIIKICK Global/Data/Position.swift`), `FieldCanvasView`, `GridDensityHeatmapRenderer`, `FieldArtworkLayout.artworkSize` (기존 컴포넌트)
- Produces: `struct HeatmapExportPreviewView: View`, `init(seed: Int = 102)` — Task 3이 `HeatmapExportPreviewView()`로 생성한다.

- [ ] **Step 1: 전체 뷰 파일 작성**

```swift
import SwiftUI
import Photos

/// GK를 제외한 9개 포지션의 목업 히트맵을 그리드로 미리 보고, 고해상도 PNG로
/// 사진앱에 저장해 확대 품질을 확인하는 임시 검증 뷰.
/// 앱의 일반 플로우에는 연결하지 않고, RootView의 `#if DEBUG` 블록에서만 띄운다.
struct HeatmapExportPreviewView: View {
    private struct Item: Identifiable {
        let position: Position
        let points: [MockHeatmapPoint]
        var id: String { position.rawValue }
    }

    private let items: [Item]

    init(seed: Int = 102) {
        items = Position.allCases
            .filter { $0 != .gk }
            .map { position in
                Item(
                    position: position,
                    points: MockHeatmapGenerator.makeSamplePoints(seed: seed, position: position)
                )
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            HeatmapExportDetailView(position: item.position, points: item.points)
                        } label: {
                            HeatmapExportThumbnail(position: item.position, points: item.points)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color.gray950)
            .navigationTitle("히트맵 내보내기 검증")
        }
    }
}

private struct HeatmapExportThumbnail: View {
    let position: Position
    let points: [MockHeatmapPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(position.uppercased)
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            FieldCanvasView { context, size in
                GridDensityHeatmapRenderer().render(
                    in: context,
                    size: size,
                    normalizedPoints: points.map(\.normalizedPoint)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
        .background(Color.gray850, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct HeatmapExportDetailView: View {
    let position: Position
    let points: [MockHeatmapPoint]

    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle, saving, success, failure(String)
    }

    var body: some View {
        VStack(spacing: 24) {
            heatmapCard
                .padding(.horizontal, 16)

            Text(statusText)
                .font(.title2SB)
                .foregroundStyle(.colorTextPrimary)

            Button(action: save) {
                Image("ic_download")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.colorTextPrimary)
                    .padding(16)
                    .background(Color.gray800, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(saveState == .saving)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle(position.uppercased)
    }

    private var heatmapCard: some View {
        FieldCanvasView { context, size in
            GridDensityHeatmapRenderer().render(
                in: context,
                size: size,
                normalizedPoints: points.map(\.normalizedPoint)
            )
        }
    }

    private var statusText: String {
        switch saveState {
        case .idle, .saving: "고해상도 이미지 저장"
        case .success: "사진 앱에 저장됐어요"
        case .failure(let message): message
        }
    }

    @MainActor
    private func save() {
        let exportCard = heatmapCard
            .frame(width: FieldArtworkLayout.artworkSize.width, height: FieldArtworkLayout.artworkSize.height)

        let renderer = ImageRenderer(content: exportCard)
        // 디바이스 스케일(2x/3x) 대신 고정된 높은 값을 써서, 시뮬레이터에서도
        // 항상 확대에 안전한 큰 PNG가 나오게 한다.
        renderer.scale = 8
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else {
            saveState = .failure("이미지를 만들지 못했어요")
            return
        }

        saveState = .saving
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveState = .failure("사진 접근 권한이 필요해요")
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: pngData, options: nil)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        saveState = success ? .success : .failure(error?.localizedDescription ?? "저장 실패")
                    }
                }
            }
        }
    }
}

#Preview("히트맵 내보내기 검증") {
    HeatmapExportPreviewView()
}
```

- [ ] **Step 2: 빌드로 컴파일 확인**

Run: `xcodebuild build -project "KIIKICK/KIIKICK.xcodeproj" -scheme KIIKICK -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Xcode Preview로 그리드 확인**

Xcode에서 이 파일을 열고 `#Preview("히트맵 내보내기 검증")` 캔버스를 띄운다.
Expected: GK를 제외한 9칸(LW/ST/RW/LM/CM/RM/LB/CB/RB)이 모두 보이고, 좌/중앙/우 포지션끼리 히트맵이 서로 다른 쪽(위/아래)에 몰려 있다 — 특히 Task 1에서 새로 추가한 RW가 LW와 위아래로 뒤집힌 모양인지, LB가 RB와 뒤집힌 모양인지 확인한다.

- [ ] **Step 4: Commit**

```bash
git add "KIIKICK/KIIKICK/Features/View/HeatmapExportPreviewView.swift"
git commit -m "[feat] 히트맵 내보내기 검증 뷰 추가 (그리드 + 상세 + 사진앱 저장)"
```

---

## Task 3: RootView에 디버그 진입점 연결 + 시뮬레이터 전체 확인

**Files:**
- Modify: `KIIKICK/KIIKICK/App/RootView.swift:10-41`

**Interfaces:**
- Consumes: `HeatmapExportPreviewView()` (Task 2)
- Produces: 없음 (최종 통합 지점)

- [ ] **Step 1: `RootView.body`를 `#if DEBUG`로 감싸고 기존 내용을 `routedContent`로 추출**

`KIIKICK/KIIKICK/App/RootView.swift` 전체를 아래로 교체한다:

```swift
//
//  RootView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        #if DEBUG
        // 히트맵 내보내기 검증을 위해 디버그 빌드에서는 검증 루트로 바로 진입한다.
        HeatmapExportPreviewView()
        #else
        routedContent
            .animation(.default, value: router.flow)
            .dismissKeyboardOnTap()
            .onAppear {
                Task {
                    // sleep(1)
                    // 이슈 #63: accessToken이 만료됐으면 refreshToken으로 재인증한다 —
                    // 실패(refreshToken도 무효)하면 세션이 지워진 채로 false가 돌아온다.
                    let isLoggedIn = await UserSession.reauthenticateIfNeeded()
                    router.finishSplash(isLoggedIn: isLoggedIn)
                }
            }
        #endif
    }

    @ViewBuilder
    private var routedContent: some View {
        Group {
            switch router.flow {
            case .splash:
                SplashView()
            case .auth:
                StartView()
            case .onboarding:
                NavigationStack {
                    SignUpNicknameView(registrationToken: nil, password: nil)
                }
            case .main:
                MainView()
                    .environment(SessionManager.shared)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
}
```

- [ ] **Step 2: 빌드로 컴파일 확인**

Run: `xcodebuild build -project "KIIKICK/KIIKICK.xcodeproj" -scheme KIIKICK -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 시뮬레이터에서 실제 실행 확인**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
open -a Simulator
xcodebuild -project "KIIKICK/KIIKICK.xcodeproj" -scheme KIIKICK -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath /tmp/kiikick-build build
xcrun simctl install "iPhone 16 Pro" /tmp/kiikick-build/Build/Products/Debug-iphonesimulator/KIIKICK.app
xcrun simctl launch "iPhone 16 Pro" com.seungjunlee.KIIKICK
```

앱이 뜨면 직접 확인:
1. 앱 실행 즉시 스플래시/로그인 없이 "히트맵 내보내기 검증" 그리드가 바로 뜬다.
2. 9칸이 GK 없이 LW/ST/RW/LM/CM/RM/LB/CB/RB로 채워져 있다.
3. 임의의 칸(예: RB)을 탭 → 상세 화면으로 들어가서 같은 히트맵이 크게 보인다.
4. 저장 버튼을 누르면 사진 접근 권한 팝업이 뜨고, 허용하면 "사진 앱에 저장됐어요"로 바뀐다.
5. 시뮬레이터의 사진 앱(Photos)을 열어 방금 저장된 이미지를 큰 배율로 확대해 블러/깨짐 없이 선명한지 확인한다.

- [ ] **Step 4: Commit**

```bash
git add "KIIKICK/KIIKICK/App/RootView.swift"
git commit -m "[chore] 디버그 빌드에서 히트맵 내보내기 검증 루트로 전환"
```

## 되돌리는 방법 (나중에)

이슈 #102 시연 플로우로 복귀할 때는 Task 3 Step 1에서 바꾼 `RootView.swift`만 `d75816f` 방식대로 되돌리면 된다 — `#if DEBUG` / `HeatmapExportPreviewView()` / `#else` / `#endif` 네 줄을 지우고, `routedContent`의 내용을 `body`로 다시 끌어올리면 원래 라우팅 플로우가 복원된다. `HeatmapExportPreviewView.swift`와 `MockHeatmapGenerator.swift`의 추가분은 그대로 남겨둬도 다른 코드에 영향 없음(둘 다 참조되지 않는 한 비활성 상태).
