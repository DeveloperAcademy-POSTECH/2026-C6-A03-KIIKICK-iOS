# 운동장 등록 + 히트맵 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** iPhone에서 위성 지도에 핀 4개를 찍어 운동장을 등록하고, 측정 기록을 운동장에 연결해 GPS 경로를 운동장 좌표계로 정규화한 히트맵으로 보여준다.

**Architecture:** `Field`(SwiftData)가 4개 꼭짓점을 저장하고, 뷰/SwiftData와 분리된 `FieldCoordinateMapper`가 bilinear 사각형 보간의 역변환(Newton-Raphson)으로 GPS 좌표를 (0~1, 0~1) 정규화 좌표로 바꾼다. `HeatmapRenderer` 프로토콜 뒤에 1차 구현(`GridDensityHeatmapRenderer`)을 두어 알고리즘을 나중에 교체할 수 있게 한다.

**Tech Stack:** SwiftUI, MapKit(`MapReader`, `MapProxy.convert`, `.imagery` 위성 스타일), SwiftData, Canvas.

## Global Constraints

- 이 프로젝트엔 XCTest 타겟이 없다. 각 태스크 검증은 `xcodebuild build` 성공 + 수동 확인으로 한다.
- 새 파일은 `KIIKICK/` (iOS 전용 fileSystemSynchronizedGroup) 아래에 만들면 Xcode가 자동으로 타겟에 포함한다. pbxproj를 직접 건드릴 일은 없다.
- 공격 방향(터치라인/골라인 구분)은 범위 밖 — 꼭짓점 4개는 순서 의미 없이 저장하고, `FieldCoordinateMapper`가 centroid 기준 각도 정렬로 자체적으로 둘레 순서를 정한다.
- 매 태스크 끝에 `git add` + `git commit` (한국어 커밋 메시지, `[feat] ...` 스타일).
- watchOS 쪽은 이번 플랜에서 건드리지 않는다 (운동장/히트맵은 iPhone 전용 기능).

---

### Task 1: `Field` SwiftData 모델 + `WorkoutRecord.field` 관계

**Files:**
- Create: `KIIKICK/KIIKICK/Field.swift`
- Modify: `KIIKICK/KIIKICK/WorkoutRecord.swift`
- Modify: `KIIKICK/KIIKICK/MyApp.swift`

**Interfaces:**
- Produces: `FieldCorner` (Codable), `Field`(`@Model`, iOS 전용) — `name: String`, `cornerA/B/C/D: FieldCorner`. `WorkoutRecord.field: Field?`.

- [ ] **Step 1: `Field` 모델 생성**

Create `KIIKICK/KIIKICK/Field.swift`:

```swift
//
//  Field.swift
//  KIIKICK
//

import Foundation
import SwiftData

struct FieldCorner: Codable {
    let latitude: Double
    let longitude: Double
}

@Model
final class Field {
    var name: String
    var cornerA: FieldCorner
    var cornerB: FieldCorner
    var cornerC: FieldCorner
    var cornerD: FieldCorner

    init(name: String, cornerA: FieldCorner, cornerB: FieldCorner, cornerC: FieldCorner, cornerD: FieldCorner) {
        self.name = name
        self.cornerA = cornerA
        self.cornerB = cornerB
        self.cornerC = cornerC
        self.cornerD = cornerD
    }
}
```

- [ ] **Step 2: `WorkoutRecord`에 `field` 관계 추가**

`KIIKICK/KIIKICK/WorkoutRecord.swift`의 `heartRateSamples` 프로퍼티 바로 아래에 추가:

```swift
    var field: Field?
```

(기존 `init(payload:)`는 그대로 둔다 — `field`는 옵셔널이라 초기화 시 자동으로 `nil`.)

- [ ] **Step 3: `MyApp`의 `ModelContainer`에 `Field` 등록**

`KIIKICK/KIIKICK/MyApp.swift`의 `modelContainer = try! ModelContainer(for: WorkoutRecord.self)` 줄을 아래로 교체:

```swift
        modelContainer = try! ModelContainer(for: WorkoutRecord.self, Field.self)
```

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/Field.swift" "KIIKICK/KIIKICK/WorkoutRecord.swift" "KIIKICK/KIIKICK/MyApp.swift"
git commit -m "[feat] Field SwiftData 모델 + WorkoutRecord.field 관계 추가"
```

---

### Task 2: `FieldCoordinateMapper` (순수 로직)

**Files:**
- Create: `KIIKICK/KIIKICK/FieldCoordinateMapper.swift`

**Interfaces:**
- Consumes: Task 1의 `Field`, `FieldCorner`.
- Produces: `FieldCoordinateMapper(field:)`, `func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint` (0~1 평면 좌표, 사각형 밖이면 0~1 범위를 벗어날 수 있음 — 호출부에서 필요하면 clamp).

- [ ] **Step 1: Bilinear 역변환 구현**

Create `KIIKICK/KIIKICK/FieldCoordinateMapper.swift`:

```swift
//
//  FieldCoordinateMapper.swift
//  KIIKICK
//
//  GPS 좌표 <-> 운동장 내 정규화 좌표(0...1, 0...1) 변환.
//  4개 꼭짓점이 완벽한 직사각형이 아니어도(GPS 핀 오차) 동작하도록
//  bilinear 사각형 보간의 역변환을 Newton-Raphson으로 근사한다.
//

import CoreLocation
import CoreGraphics

struct FieldCoordinateMapper {
    private let p00: CGPoint
    private let p10: CGPoint
    private let p11: CGPoint
    private let p01: CGPoint

    init(field: Field) {
        let corners = [field.cornerA, field.cornerB, field.cornerC, field.cornerD]
        let points = corners.map { CGPoint(x: $0.longitude, y: $0.latitude) }

        let centroid = CGPoint(
            x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
            y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
        )
        // centroid 기준 각도로 정렬하면 둘레를 따라가는 순서(p00->p10->p11->p01)가 나온다.
        let ordered = points.sorted { a, b in
            atan2(a.y - centroid.y, a.x - centroid.x) < atan2(b.y - centroid.y, b.x - centroid.x)
        }
        p00 = ordered[0]
        p10 = ordered[1]
        p11 = ordered[2]
        p01 = ordered[3]
    }

    /// 위도/경도 -> 운동장 내 정규화 좌표 (x: 0...1, y: 0...1 근방).
    func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let target = CGPoint(x: coordinate.longitude, y: coordinate.latitude)
        var u: CGFloat = 0.5
        var v: CGFloat = 0.5

        for _ in 0..<12 {
            let f = bilinear(u: u, v: v)
            let rx = f.x - target.x
            let ry = f.y - target.y

            let fxu = (1 - v) * (p10.x - p00.x) + v * (p11.x - p01.x)
            let fxv = (1 - u) * (p01.x - p00.x) + u * (p11.x - p10.x)
            let fyu = (1 - v) * (p10.y - p00.y) + v * (p11.y - p01.y)
            let fyv = (1 - u) * (p01.y - p00.y) + u * (p11.y - p10.y)

            let det = fxu * fyv - fxv * fyu
            guard abs(det) > 1e-12 else { break }

            let du = (rx * fyv - ry * fxv) / det
            let dv = (fxu * ry - fyu * rx) / det

            u -= du
            v -= dv

            if abs(du) < 1e-9 && abs(dv) < 1e-9 { break }
        }

        return CGPoint(x: u, y: v)
    }

    private func bilinear(u: CGFloat, v: CGFloat) -> CGPoint {
        let x = (1 - u) * (1 - v) * p00.x + u * (1 - v) * p10.x + (1 - u) * v * p01.x + u * v * p11.x
        let y = (1 - u) * (1 - v) * p00.y + u * (1 - v) * p10.y + (1 - u) * v * p01.y + u * v * p11.y
        return CGPoint(x: x, y: y)
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/FieldCoordinateMapper.swift"
git commit -m "[feat] GPS -> 운동장 정규화 좌표 변환 FieldCoordinateMapper 추가"
```

---

### Task 3: 운동장 등록 화면 + 운동장 목록 화면

**Files:**
- Create: `KIIKICK/KIIKICK/FieldRegistrationView.swift`
- Create: `KIIKICK/KIIKICK/FieldListView.swift`
- Modify: `KIIKICK/KIIKICK/ContentView.swift`

**Interfaces:**
- Consumes: Task 1의 `Field`, `FieldCorner`.
- Produces: `FieldListView`(진입점), `FieldRegistrationView` — ContentView 툴바에서 `FieldListView`로 이동 가능.

- [ ] **Step 1: 위성 지도 + 핀 4개 등록 화면**

Create `KIIKICK/KIIKICK/FieldRegistrationView.swift`:

```swift
//
//  FieldRegistrationView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import SwiftData

struct FieldRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pins: [CLLocationCoordinate2D] = []
    @State private var fieldName: String = ""
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 12) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(Array(pins.enumerated()), id: \.offset) { index, coordinate in
                        Marker("\(index + 1)", coordinate: coordinate)
                    }
                }
                .mapStyle(.imagery(elevation: .realistic))
                .gesture(
                    SpatialTapGesture()
                        .onEnded { event in
                            guard pins.count < 4,
                                  let coordinate = proxy.convert(event.location, from: .local) else { return }
                            pins.append(coordinate)
                        }
                )
            }
            .frame(height: 360)

            Text("\(pins.count)/4 지점 선택됨")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("마지막 핀 취소") {
                    if !pins.isEmpty { pins.removeLast() }
                }
                .disabled(pins.isEmpty)

                Spacer()

                Button("초기화") { pins.removeAll() }
                    .disabled(pins.isEmpty)
            }

            if pins.count == 4 {
                TextField("운동장 이름", text: $fieldName)
                    .textFieldStyle(.roundedBorder)

                Button("저장") { save() }
                    .disabled(fieldName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("운동장 등록")
    }

    private func save() {
        guard pins.count == 4 else { return }
        let field = Field(
            name: fieldName,
            cornerA: FieldCorner(latitude: pins[0].latitude, longitude: pins[0].longitude),
            cornerB: FieldCorner(latitude: pins[1].latitude, longitude: pins[1].longitude),
            cornerC: FieldCorner(latitude: pins[2].latitude, longitude: pins[2].longitude),
            cornerD: FieldCorner(latitude: pins[3].latitude, longitude: pins[3].longitude)
        )
        modelContext.insert(field)
        try? modelContext.save()
        dismiss()
    }
}
```

- [ ] **Step 2: 운동장 목록 화면**

Create `KIIKICK/KIIKICK/FieldListView.swift`:

```swift
//
//  FieldListView.swift
//  KIIKICK
//

import SwiftUI
import SwiftData

struct FieldListView: View {
    @Query(sort: \Field.name) private var fields: [Field]
    @State private var isPresentingRegistration = false

    var body: some View {
        List(fields) { field in
            Text(field.name)
        }
        .overlay {
            if fields.isEmpty {
                Text("등록된 운동장이 없습니다")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("운동장 관리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("추가") { isPresentingRegistration = true }
            }
        }
        .sheet(isPresented: $isPresentingRegistration) {
            NavigationStack {
                FieldRegistrationView()
            }
        }
    }
}
```

- [ ] **Step 3: `ContentView`에서 운동장 목록으로 진입 가능하게**

`KIIKICK/KIIKICK/ContentView.swift`의 `.navigationTitle("측정 기록")` 바로 아래에 추가:

```swift
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("운동장") {
                        FieldListView()
                    }
                }
            }
```

(이미 `#if DEBUG` 블록 안에 `.toolbar { ... }`가 있으므로, 이 새 `.toolbar`는 그 바로 위/별개 modifier로 추가한다 — SwiftUI는 `.toolbar`를 여러 번 체이닝해도 각 `ToolbarItem`이 합쳐진다.)

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

시뮬레이터에서 "운동장" 버튼 → "추가" → 지도를 네 번 탭해서 핀이 찍히는지, 이름 입력 후 저장하면 목록에 뜨는지 확인.

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/FieldRegistrationView.swift" "KIIKICK/KIIKICK/FieldListView.swift" "KIIKICK/KIIKICK/ContentView.swift"
git commit -m "[feat] 위성 지도 4핀 운동장 등록 화면 + 운동장 목록 화면"
```

---

### Task 4: `WorkoutDetailView`에 운동장 선택 UI 추가

**Files:**
- Modify: `KIIKICK/KIIKICK/WorkoutDetailView.swift`

**Interfaces:**
- Consumes: Task 1의 `Field`, Task 3의 `FieldListView`(패턴 참고).
- Produces: `WorkoutDetailView`의 `record.field` 갱신 UI — Task 6이 이 `record.field`를 읽어 히트맵을 그린다.

- [ ] **Step 1: 운동장 선택 시트 추가**

`KIIKICK/KIIKICK/WorkoutDetailView.swift` 맨 위에 `import SwiftData` 추가, `struct WorkoutDetailView: View {` 바로 아래에 추가:

```swift
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Field.name) private var fields: [Field]
    @State private var isPresentingFieldPicker = false
```

`HStack(spacing: 12) { StatTile(...) }` 블록(칼로리/거리/시간 타일) 바로 아래에 추가:

```swift
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동장")
                        .font(.headline)
                    Button(record.field?.name ?? "운동장을 선택해주세요") {
                        isPresentingFieldPicker = true
                    }
                }
```

`.onDisappear { playbackTask?.cancel() }` 바로 아래에 추가 (sheet 모디파이어):

```swift
        .sheet(isPresented: $isPresentingFieldPicker) {
            NavigationStack {
                List(fields) { field in
                    Button(field.name) {
                        record.field = field
                        try? modelContext.save()
                        isPresentingFieldPicker = false
                    }
                }
                .overlay {
                    if fields.isEmpty {
                        Text("등록된 운동장이 없습니다")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("운동장 선택")
            }
        }
```

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/WorkoutDetailView.swift"
git commit -m "[feat] 측정 기록 Detail 화면에 운동장 선택 UI 추가"
```

---

### Task 5: `HeatmapRenderer` 프로토콜 + `GridDensityHeatmapRenderer`

**Files:**
- Create: `KIIKICK/KIIKICK/HeatmapRenderer.swift`

**Interfaces:**
- Produces: `protocol HeatmapRenderer { func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint]) }`, `struct GridDensityHeatmapRenderer: HeatmapRenderer`. Task 6이 이 프로토콜을 `FieldHeatmapView`에서 사용한다.

- [ ] **Step 1: 그리드 밀도 렌더러 구현**

Create `KIIKICK/KIIKICK/HeatmapRenderer.swift`:

```swift
//
//  HeatmapRenderer.swift
//  KIIKICK
//
//  히트맵을 실제로 어떻게 그릴지는 이 프로토콜 뒤로 숨긴다.
//  지금은 그리드 밀도 방식(GridDensityHeatmapRenderer)만 있고,
//  나중에 보간/스무딩이 들어간 다른 구현으로 교체 가능하다.
//

import SwiftUI

protocol HeatmapRenderer {
    /// normalizedPoints: 운동장 내 정규화 좌표 (x: 0...1, y: 0...1). 범위를 벗어난 점은 구현체가 알아서 무시해도 된다.
    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint])
}

struct GridDensityHeatmapRenderer: HeatmapRenderer {
    let columns: Int
    let rows: Int

    init(columns: Int = 20, rows: Int = 13) {
        self.columns = columns
        self.rows = rows
    }

    func render(in context: GraphicsContext, size: CGSize, normalizedPoints: [CGPoint]) {
        guard !normalizedPoints.isEmpty else { return }

        var counts = [Int](repeating: 0, count: columns * rows)
        for point in normalizedPoints {
            guard point.x >= 0, point.x <= 1, point.y >= 0, point.y <= 1 else { continue }
            let col = min(columns - 1, max(0, Int(point.x * CGFloat(columns))))
            let row = min(rows - 1, max(0, Int(point.y * CGFloat(rows))))
            counts[row * columns + col] += 1
        }

        guard let maxCount = counts.max(), maxCount > 0 else { return }

        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)

        for row in 0..<rows {
            for col in 0..<columns {
                let count = counts[row * columns + col]
                guard count > 0 else { continue }
                let opacity = Double(count) / Double(maxCount)
                let rect = CGRect(
                    x: CGFloat(col) * cellWidth,
                    y: CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                context.fill(Path(rect), with: .color(.red.opacity(0.15 + opacity * 0.65)))
            }
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/HeatmapRenderer.swift"
git commit -m "[feat] HeatmapRenderer 프로토콜 + 그리드 밀도 기본 구현 추가"
```

---

### Task 6: `FieldHeatmapView` + `WorkoutDetailView` 통합

**Files:**
- Create: `KIIKICK/KIIKICK/FieldHeatmapView.swift`
- Modify: `KIIKICK/KIIKICK/WorkoutDetailView.swift`

**Interfaces:**
- Consumes: Task 2의 `FieldCoordinateMapper`, Task 5의 `HeatmapRenderer`/`GridDensityHeatmapRenderer`, Task 1의 `Field`.

- [ ] **Step 1: `FieldHeatmapView` 생성**

Create `KIIKICK/KIIKICK/FieldHeatmapView.swift`:

```swift
//
//  FieldHeatmapView.swift
//  KIIKICK
//

import SwiftUI
import CoreLocation

struct FieldHeatmapView: View {
    let field: Field
    let points: [TrackPoint]
    let renderer: HeatmapRenderer

    init(field: Field, points: [TrackPoint], renderer: HeatmapRenderer = GridDensityHeatmapRenderer()) {
        self.field = field
        self.points = points
        self.renderer = renderer
    }

    var body: some View {
        let mapper = FieldCoordinateMapper(field: field)
        let normalizedPoints = points.map {
            mapper.normalize(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
        }

        Canvas { context, size in
            // 1. 배경
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

            // 2~3. 히트맵
            renderer.render(in: context, size: size, normalizedPoints: normalizedPoints)

            // 4. 필드 테두리
            context.stroke(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white),
                lineWidth: 2
            )
        }
        .aspectRatio(105.0 / 68.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
```

- [ ] **Step 2: `WorkoutDetailView`에 히트맵 섹션 추가**

`KIIKICK/KIIKICK/WorkoutDetailView.swift`에서 Task 4가 추가한 "운동장" `VStack` 블록(버튼 포함) 바로 아래에 추가:

```swift
                if let field = record.field {
                    Text("히트맵")
                        .font(.headline)
                    FieldHeatmapView(field: field, points: record.points)
                }
```

- [ ] **Step 3: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 전체 흐름 수동 확인**

1. "운동장" 메뉴에서 새 운동장을 등록 (위성 지도에서 4곳 탭 + 이름 저장).
2. DEBUG 전용 "테스트 데이터 추가"로 가짜 기록을 하나 만듦 (또는 실제 watch 측정 기록 사용).
3. 그 기록의 Detail 화면에서 "운동장 선택"으로 방금 등록한 운동장을 연결.
4. 히트맵 섹션에 105:68 비율의 검은 배경 + 흰 테두리 캔버스와 빨간 밀도 사각형들이 보이는지 확인.

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/FieldHeatmapView.swift" "KIIKICK/KIIKICK/WorkoutDetailView.swift"
git commit -m "[feat] FieldHeatmapView 추가 + WorkoutDetailView에 히트맵 통합"
```
