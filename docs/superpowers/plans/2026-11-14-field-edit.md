# 운동장 바꾸기 기능 구현 계획 (이슈 #96)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ReadyForDetailView와 AnalysisDetailView 양쪽에서 경기의 운동장을 바꿀 수 있게 하고, 이미 제출된 경기는 서버 값(쿼터 `workout.field` 또는 경기 `venueId`)까지 갱신한다.

**Architecture:** 쿼터 → 운동장 오버레이와 로컬 저장·롤백을 담당하는 값 타입 `FieldAssignment`(Domain)를 두 화면이 공유한다. UI는 `FieldChangeRow` 하나를 경기 단위(일괄)와 쿼터 단위 두 곳에 꽂는다. 네트워킹은 `ReadyForDetailView`에서 `WorkoutSubmissionStore`로 빼내고, 제출된 경기의 운동장 반영은 `FieldServerSync`가 "재전송(B) 시도 → `PATCH /matches`(A) 폴백" 순서로 처리한다.

**Tech Stack:** Swift 6 / SwiftUI, SwiftData, 기존 `Provider`/`Endpoint` 네트워크 레이어.

**설계 문서:** `docs/superpowers/specs/2026-11-14-field-edit-design.md`

## Global Constraints

- 브랜치는 `feat/#96-field-edit`. 커밋 메시지는 한국어 + 태그 필수(`rules/GIT.md`): 제목 50자 이내, 예 `[feat] 운동장 변경 행 추가`.
- 주석과 사용자 노출 문구는 한국어.
- 이 프로젝트엔 XCTest 타겟이 없다. 단위 검증은 `Tests/*Checks.swift`(독립 `@main` 실행 파일, `precondition`으로 단정) + `scripts/validation/check-*.sh`(`xcrun swiftc`로 필요한 파일만 컴파일해 실행) 패턴을 따른다. 기존 예시: `Tests/VenueChecks.swift`, `scripts/validation/check-venues.sh`.
- 빌드 검증: `cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- 색/타이포는 `rules/DESIGN.md` 토큰만 사용한다(`.colorTextPrimary`, `.colorTextSecondary`, `.colorSurfacePrimary`, `.mint500`, `.label1M`, `.body4R` 등). 하드코딩 금지.
- SwiftUI 코드는 `swiftui-pro` 스킬 규칙을 따른다.
- `@Observable` 매크로는 체크 스크립트 컴파일에서 피한다 — 공유 로직은 값 타입으로 두고 뷰가 `@State`로 들고 있는다.
- `rules/GIT.md`는 `develop`로 PR을 열라고 하지만 **origin에 `develop`이 없다**(`git ls-remote --heads origin develop` 결과 없음). 최근 이력대로 `main`을 대상으로 PR을 연다.

## File Structure

| 파일 | 역할 |
|---|---|
| `KIIKICK/KIIKICK/Domain/FieldAssignment.swift` (신규) | 쿼터별 운동장 오버레이, 적용 범위 계산, 로컬 저장 실패 시 롤백 |
| `KIIKICK/KIIKICK/Features/Components/FieldChangeRow.swift` (신규) | "운동장 · 〈이름〉 / 변경" 행 (미지정이면 "지정하기") |
| `KIIKICK/KIIKICK/Respository/WorkoutSubmissionStore.swift` (신규) | `workout-submissions` 제출 — 최초 제출과 재전송을 한 경로로 |
| `KIIKICK/KIIKICK/Respository/FieldServerSync.swift` (신규) | 제출된 경기의 운동장 서버 반영: 재전송(B) → `PATCH /matches`(A) 폴백 |
| `KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift` (수정) | `FieldAssignment`/`FieldChangeRow` 사용, 네트워킹 제거 |
| `KIIKICK/KIIKICK/Features/Components/CardQuarterView.swift` (수정) | 쿼터 단위 운동장 변경 행 슬롯 추가 |
| `KIIKICK/KIIKICK/Features/View/Analysis/AnalysisDetailView.swift` (수정) | 운동장 변경 진입점 + 서버 동기화 호출 |
| `Tests/FieldAssignmentChecks.swift`, `Tests/FieldServerSyncChecks.swift` (신규) | 단위 검증 |
| `scripts/validation/check-field-assignment.sh`, `scripts/validation/check-field-server-sync.sh` (신규) | 검증 실행 스크립트 |

---

### Task 1: `FieldAssignment` 값 타입

**Files:**
- Create: `KIIKICK/KIIKICK/Domain/FieldAssignment.swift`
- Test: `Tests/FieldAssignmentChecks.swift`, `scripts/validation/check-field-assignment.sh`

**Interfaces:**
- Consumes: `Field`(`KIIKICK/KIIKICK/Data/Field.swift`), `WorkoutRecord`(`KIIKICK/KIIKICK/Data/WorkoutRecord.swift`)
- Produces:
  - `enum FieldAssignmentScope: Equatable { case allQuarters; case quarter(UUID) }`
  - `struct FieldAssignment`
    - `struct QuarterInput { let id: UUID; let record: WorkoutRecord?; let field: Field? }`
    - `init(quarters: [QuarterInput])`
    - `func field(for quarterID: UUID) -> Field?`
    - `var missingQuarterIDs: [UUID]`, `var hasMissingFields: Bool`, `var isEditable: Bool`, `var commonField: Field?`
    - `func targetQuarterIDs(for scope: FieldAssignmentScope) -> [UUID]`
    - `mutating func apply(_ field: Field, to scope: FieldAssignmentScope, save: () throws -> Void) throws`

- [ ] **Step 1: 실패하는 검증 작성**

`Tests/FieldAssignmentChecks.swift`:

```swift
import Foundation
import SwiftData

@main
struct FieldAssignmentChecks {
    @MainActor
    static func main() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Field.self, WorkoutRecord.self, configurations: configuration)
        let context = container.mainContext

        let fieldA = makeField(name: "A구장")
        let fieldB = makeField(name: "B구장")
        context.insert(fieldA)
        context.insert(fieldB)
        let first = makeRecord()
        let second = makeRecord()
        first.field = fieldA
        second.field = fieldA
        context.insert(first)
        context.insert(second)
        try context.save()

        let firstID = UUID()
        let secondID = UUID()
        let inputs = [
            FieldAssignment.QuarterInput(id: firstID, record: first, field: nil),
            FieldAssignment.QuarterInput(id: secondID, record: second, field: nil),
        ]

        // 초기 상태: record.field가 오버레이로 올라오고 공통 운동장이 잡힌다.
        var assignment = FieldAssignment(quarters: inputs)
        precondition(assignment.field(for: firstID) === fieldA)
        precondition(assignment.commonField === fieldA)
        precondition(!assignment.hasMissingFields)
        precondition(assignment.isEditable)

        // 일괄 적용
        try assignment.apply(fieldB, to: .allQuarters, save: { try context.save() })
        precondition(assignment.field(for: firstID) === fieldB)
        precondition(assignment.field(for: secondID) === fieldB)
        precondition(first.field === fieldB && second.field === fieldB)

        // 쿼터 단위 적용 — 다른 쿼터는 그대로
        try assignment.apply(fieldA, to: .quarter(secondID), save: { try context.save() })
        precondition(assignment.field(for: firstID) === fieldB)
        precondition(assignment.field(for: secondID) === fieldA)
        precondition(assignment.commonField == nil)

        // 저장 실패 시 오버레이와 record.field가 모두 되돌아온다.
        struct SaveFailure: Error {}
        do {
            try assignment.apply(fieldB, to: .allQuarters, save: { throw SaveFailure() })
            preconditionFailure("저장 실패가 전달되지 않았습니다")
        } catch is SaveFailure {
            precondition(assignment.field(for: firstID) === fieldB)
            precondition(assignment.field(for: secondID) === fieldA)
            precondition(first.field === fieldB && second.field === fieldA)
        }

        // 운동장 미지정 쿼터는 missingQuarterIDs로 드러난다.
        let third = makeRecord()
        context.insert(third)
        try context.save()
        let thirdID = UUID()
        let withMissing = FieldAssignment(quarters: inputs + [
            FieldAssignment.QuarterInput(id: thirdID, record: third, field: nil),
        ])
        precondition(withMissing.missingQuarterIDs == [thirdID])
        precondition(withMissing.hasMissingFields)
        precondition(withMissing.targetQuarterIDs(for: .allQuarters) == [firstID, secondID, thirdID])
        precondition(withMissing.targetQuarterIDs(for: .quarter(thirdID)) == [thirdID])

        // 로컬 기록이 없는(서버 복원) 엔트리는 편집 대상이 아니다.
        let restored = FieldAssignment(quarters: [
            FieldAssignment.QuarterInput(id: firstID, record: nil, field: fieldA),
        ])
        precondition(!restored.isEditable)
        precondition(restored.field(for: firstID) === fieldA)

        print("FieldAssignmentChecks 통과")
    }

    private static func makeField(name: String) -> Field {
        let corners = (0..<4).map { index in
            FieldCorner(latitude: 37.0 + Double(index) * 0.001, longitude: 127.0 + Double(index) * 0.001)
        }
        return Field(
            name: name,
            cornerA: corners[0], cornerB: corners[1], cornerC: corners[2], cornerD: corners[3]
        )
    }

    private static func makeRecord() -> WorkoutRecord {
        WorkoutRecord(payload: WorkoutPayload.fake())
    }
}
```

`scripts/validation/check-field-assignment.sh`:

```bash
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-field-assignment.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
app=KIIKICK/KIIKICK
global="KIIKICK/KIIKICK Global"
xcrun swiftc -parse-as-library \
  "$global"/Data/{TrackPoint,HeartRateSample,MatchEvent,WorkoutPayload,Position}.swift \
  "$app"/Data/{Field,WorkoutRecord}.swift \
  "$app"/Domain/FieldAssignment.swift \
  Tests/FieldAssignmentChecks.swift -o "$check_dir/checks"
"$check_dir/checks"
```

실행 권한을 준다: `chmod +x scripts/validation/check-field-assignment.sh`

- [ ] **Step 2: 실패를 확인한다**

Run: `./scripts/validation/check-field-assignment.sh`
Expected: 컴파일 실패 — `cannot find 'FieldAssignment' in scope`

참고: `Field`/`WorkoutRecord`의 실제 이니셜라이저 시그니처를 먼저 확인하고(`KIIKICK/KIIKICK/Data/Field.swift`), 위 `makeField`/`makeRecord`가 맞지 않으면 그 파일의 시그니처에 맞춰 고친다. `WorkoutPayload.fake()`는 `#if DEBUG` 안에 있으니, 스크립트 컴파일에서 빠지면 `makeRecord`가 `WorkoutPayload`를 직접 구성하도록 바꾼다.

- [ ] **Step 3: 최소 구현**

`KIIKICK/KIIKICK/Domain/FieldAssignment.swift`:

```swift
//
//  FieldAssignment.swift
//  KIIKICK
//
//  이슈 #96: 쿼터별 운동장을 바꾸는 공통 로직. AnalysisQuarter가 값 타입이라
//  record.field만 고쳐도 화면이 갱신되지 않으므로, 뷰가 @State로 들고 있는 이
//  오버레이를 히트맵(TrackingMapPager)에 넘긴다.
//
//  `save`를 주입받는 이유: 로컬 저장이 실패하면 메모리 상태와 record.field를 모두
//  원래대로 되돌려야 하고, 그 롤백을 ModelContext 없이 검증할 수 있어야 한다.
//

import Foundation
import SwiftData

enum FieldAssignmentScope: Equatable {
    /// 경기의 모든 쿼터에 같은 운동장을 적용한다(기본).
    case allQuarters
    case quarter(UUID)
}

struct FieldAssignment {
    struct QuarterInput {
        let id: UUID
        let record: WorkoutRecord?
        /// 서버에서 복원된 엔트리처럼 로컬 기록이 없을 때의 표시용 운동장.
        let field: Field?
    }

    private var fieldsByQuarterID: [UUID: Field]
    private let recordsByQuarterID: [UUID: WorkoutRecord]
    private let quarterIDs: [UUID]

    init(quarters: [QuarterInput]) {
        var fields: [UUID: Field] = [:]
        var records: [UUID: WorkoutRecord] = [:]
        for quarter in quarters {
            if let record = quarter.record {
                records[quarter.id] = record
            }
            if let field = quarter.record?.field ?? quarter.field {
                fields[quarter.id] = field
            }
        }
        quarterIDs = quarters.map(\.id)
        fieldsByQuarterID = fields
        recordsByQuarterID = records
    }

    func field(for quarterID: UUID) -> Field? { fieldsByQuarterID[quarterID] }

    var missingQuarterIDs: [UUID] { quarterIDs.filter { fieldsByQuarterID[$0] == nil } }

    var hasMissingFields: Bool { !missingQuarterIDs.isEmpty }

    /// 로컬 기록이 없으면 바꿀 대상이 없다(서버에서 복원한 엔트리).
    var isEditable: Bool { !recordsByQuarterID.isEmpty }

    /// 모든 쿼터가 같은 운동장일 때 그 운동장, 쿼터마다 다르거나 비어 있으면 nil.
    var commonField: Field? {
        guard let first = quarterIDs.first, let field = fieldsByQuarterID[first] else { return nil }
        for id in quarterIDs.dropFirst() where fieldsByQuarterID[id] !== field { return nil }
        return field
    }

    func targetQuarterIDs(for scope: FieldAssignmentScope) -> [UUID] {
        switch scope {
        case .allQuarters: quarterIDs
        case .quarter(let id): quarterIDs.contains(id) ? [id] : []
        }
    }

    mutating func apply(
        _ field: Field,
        to scope: FieldAssignmentScope,
        save: () throws -> Void
    ) throws {
        let targets = targetQuarterIDs(for: scope)
        guard !targets.isEmpty else { return }
        let previousOverlay = fieldsByQuarterID
        var previousRecordFields: [UUID: Field?] = [:]
        for id in targets {
            previousRecordFields[id] = recordsByQuarterID[id]?.field
            recordsByQuarterID[id]?.field = field
            fieldsByQuarterID[id] = field
        }
        do {
            try save()
        } catch {
            for id in targets {
                recordsByQuarterID[id]?.field = previousRecordFields[id] ?? nil
            }
            fieldsByQuarterID = previousOverlay
            throw error
        }
    }
}
```

- [ ] **Step 4: 통과를 확인한다**

Run: `./scripts/validation/check-field-assignment.sh`
Expected: `FieldAssignmentChecks 통과`

- [ ] **Step 5: 커밋**

```bash
git add KIIKICK/KIIKICK/Domain/FieldAssignment.swift Tests/FieldAssignmentChecks.swift scripts/validation/check-field-assignment.sh
git commit -m "[feat] 쿼터별 운동장 적용 로직 추가"
```

---

### Task 2: `FieldChangeRow` 컴포넌트

**Files:**
- Create: `KIIKICK/KIIKICK/Features/Components/FieldChangeRow.swift`

**Interfaces:**
- Consumes: `Field`, 디자인 토큰(`rules/DESIGN.md`)
- Produces: `struct FieldChangeRow: View` — `init(field: Field?, action: @escaping () -> Void)`

- [ ] **Step 1: 컴포넌트 작성**

```swift
//
//  FieldChangeRow.swift
//  KIIKICK
//
//  이슈 #96: 운동장 변경 진입점. 분석 준비(ReadyForDetailView)의 경기 단위·쿼터 단위,
//  분석 상세(AnalysisDetailView) 세 자리에서 같은 행을 쓴다.
//
//  DESIGN-GAP: Figma에 운동장 변경 행이 아직 없다 — 같은 화면의 "포지션" 행
//  (CardQuarterView, label1M + 우측 컨트롤)과 같은 구성으로 맞췄다.
//

import SwiftUI

struct FieldChangeRow: View {
    let field: Field?
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("운동장")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text(field?.name ?? "미지정")
                .font(.body4R)
                .foregroundStyle(field == nil ? .colorTextSecondary : .colorTextPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(action: action) {
                HStack(spacing: 2) {
                    Text(field == nil ? "지정하기" : "변경")
                        .font(.caption1M)
                        .foregroundStyle(.mint500)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.mint500)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(field == nil ? "운동장 지정하기" : "운동장 변경, 현재 \(field?.name ?? "")")
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FieldChangeRow(field: nil) {}
    }
    .padding()
    .background(Color.gray950)
}
```

- [ ] **Step 2: 빌드 확인**

Run: `cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: BUILD SUCCEEDED

(`.caption1M`/`.label1M`/`.body4R`가 없으면 `rules/DESIGN.md`에서 가장 가까운 토큰으로 바꾼다. 하드코딩한 폰트/색은 쓰지 않는다.)

- [ ] **Step 3: 커밋**

```bash
git add KIIKICK/KIIKICK/Features/Components/FieldChangeRow.swift
git commit -m "[feat] 운동장 변경 행 컴포넌트 추가"
```

---

### Task 3: ReadyForDetailView에 운동장 변경 붙이기

**Files:**
- Modify: `KIIKICK/KIIKICK/Features/Components/CardQuarterView.swift` (쿼터 단위 행 슬롯)
- Modify: `KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift:30-60`(상태), `:62-140`(body), `:196-237`(field 접근/assignMissingFields)

**Interfaces:**
- Consumes: Task 1의 `FieldAssignment`/`FieldAssignmentScope`, Task 2의 `FieldChangeRow`
- Produces: 없음(화면 내부 변경)

- [ ] **Step 1: `CardQuarterView`에 운동장 행 슬롯 추가**

`field` 프로퍼티 바로 아래에 콜백을 추가하고, 포지션 행과 히트맵 사이에 행을 넣는다.

```swift
    var field: Field? = nil
    /// 이슈 #96: 이 쿼터만 운동장을 바꿀 때. nil이면 행을 숨긴다(쿼터가 하나뿐일 때 등).
    var onChangeField: (() -> Void)? = nil
```

```swift
            if let onChangeField {
                FieldChangeRow(field: field, action: onChangeField)
            }

            TrackingMapPager(field: field, points: points, isAttackDirectionReversed: isFlipped)
                .frame(height: 248)
```

- [ ] **Step 2: `ReadyForDetailView` 상태를 `FieldAssignment`로 교체**

`@State private var fieldsByQuarterID: [UUID: Field]`를 지우고 다음을 넣는다.

```swift
    @State private var assignment: FieldAssignment
    @State private var pendingField: Field?
    @State private var fieldPickerScope: FieldAssignmentScope = .allQuarters
```

`init`의 `fieldsByQuarterID` 구성 블록을 교체한다.

```swift
        _assignment = State(initialValue: FieldAssignment(
            quarters: entry.detail.quarters.map {
                FieldAssignment.QuarterInput(id: $0.id, record: $0.sourceRecord, field: $0.field)
            }
        ))
```

`field(for:)`와 `hasMissingFields`를 오버레이에 위임한다.

```swift
    private var hasMissingFields: Bool { assignment.hasMissingFields }

    private func field(for quarter: AnalysisQuarter) -> Field? { assignment.field(for: quarter.id) }
```

- [ ] **Step 3: 진입점과 적용 로직 연결**

`directionGuide` 아래에 경기 단위 행을 넣는다.

```swift
                directionGuide

                FieldChangeRow(field: assignment.commonField) {
                    fieldPickerScope = .allQuarters
                    isPresentingFieldPicker = true
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
```

`CardQuarterView` 호출에 쿼터 단위 진입점을 추가한다.

```swift
                        positionChangeText: positionChangeText(index: index, original: quarter.position),
                        onChangeField: quarters.count > 1 ? {
                            fieldPickerScope = .quarter(quarter.id)
                            isPresentingFieldPicker = true
                        } : nil
```

`fieldAssignmentNotice`의 CTA도 같은 경로를 쓰게 한다(미지정 쿼터를 한 번에 채우는 기존 의도 유지).

```swift
            CtaView(text: "운동장 지정하기", type: .secondary, size: .small) {
                fieldPickerScope = .allQuarters
                isPresentingFieldPicker = true
            }
```

`assignMissingFields(_:)`를 지우고 다음으로 대체한다 — 범위 선택은 경기 단위 진입이고 쿼터가 2개 이상일 때만 묻는다.

```swift
    private func handlePickedField(_ field: Field) {
        if case .allQuarters = fieldPickerScope, quarters.count > 1, !assignment.hasMissingFields {
            pendingField = field
            return
        }
        // 미지정 쿼터가 있는 상태(최초 지정)나 쿼터 1개는 묻지 않고 전부 적용한다.
        applyField(field, to: fieldPickerScope)
    }

    private func applyField(_ field: Field, to scope: FieldAssignmentScope) {
        do {
            try assignment.apply(field, to: scope, save: { try modelContext.save() })
        } catch {
            saveError = error.localizedDescription
        }
    }
```

`navigationDestination`을 새 핸들러로 바꾸고, 범위 확인 다이얼로그를 붙인다.

```swift
        .navigationDestination(isPresented: $isPresentingFieldPicker) {
            FieldListView(onFieldSelected: handlePickedField)
        }
        .confirmationDialog(
            "이 운동장을 어디에 적용할까요?",
            isPresented: Binding(get: { pendingField != nil }, set: { if !$0 { pendingField = nil } }),
            titleVisibility: .visible
        ) {
            Button("모든 쿼터에 적용") {
                if let pendingField { applyField(pendingField, to: .allQuarters) }
                pendingField = nil
            }
            Button("취소", role: .cancel) { pendingField = nil }
        }
```

- [ ] **Step 4: 제출 경로가 새 오버레이를 쓰는지 확인**

`saveAndAnalyze`의 `fieldName` 계산은 이미 `field(for:)`를 쓰므로 그대로 둔다. `submitWorkouts`는 `record.field`를 읽고, Task 1의 `apply`가 `record.field`까지 저장하므로 추가 변경이 없다. 확인만 하고 넘어간다.

Run: `grep -n "record.field\|\.field" KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift`
Expected: 남은 `fieldsByQuarterID` 참조가 없고, 제출 경로는 `record.field`만 읽는다.

- [ ] **Step 5: 빌드와 기존 검증 확인**

Run: `cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: BUILD SUCCEEDED

Run: `./scripts/validation/check-field-assignment.sh && ./scripts/validation/check-venues.sh`
Expected: 둘 다 통과

- [ ] **Step 6: 시뮬레이터 수동 확인**

분석 준비 화면에서 (1) 상단 행의 "변경"으로 전체 쿼터 운동장이 바뀌는지, (2) 쿼터 카드의 "변경"으로 그 쿼터만 바뀌는지, (3) 바뀐 직후 히트맵이 새 운동장으로 다시 그려지는지, (4) 미지정 쿼터가 있을 때 기존 경고와 "분석 보기" 비활성이 그대로인지 확인한다.

- [ ] **Step 7: 커밋**

```bash
git add KIIKICK/KIIKICK/Features/Components/CardQuarterView.swift KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift
git commit -m "[feat] 분석 준비에서 운동장 변경 지원"
```

---

### Task 4: `WorkoutSubmissionStore` 추출

**Files:**
- Create: `KIIKICK/KIIKICK/Respository/WorkoutSubmissionStore.swift`
- Modify: `KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift:239-300`(submitWorkouts 등 제거)

**Interfaces:**
- Consumes: `WorkoutRecord`, `Field`, `VenueStore.ensureUploaded(_:context:)`, `MatchEndpoints.detail(matchId:)`, `QuarterWorkoutEndpoints.submit(matchId:quarters:ifMatch:idempotencyKey:)`, `Provider`
- Produces:
  - `enum WorkoutSubmissionStore`
    - `enum Mode { case firstSubmission, resubmission }`
    - `static func submit(records: [WorkoutRecord], positions: [String], mode: Mode, context: ModelContext, provider: (any Provider)? = nil) async throws`
    - `static func ensureFieldsAreUploaded(for records: [WorkoutRecord], context: ModelContext, provider: (any Provider)? = nil) async throws`
    - `static func workoutFieldPayload(for field: Field?) -> WorkoutFieldPayload?`

- [ ] **Step 1: 기존 코드를 그대로 옮긴다**

`ReadyForDetailView`의 `submitWorkouts()` / `repairDuplicateQuarterIDs(in:)` / `ensureFieldsAreUploaded(for:)` / `workoutFieldPayload(for:)` / `requestSummary(...)` / `prettyPrintedJSON(...)`과 `logger`를 새 파일로 옮긴다. 주석(422 timestamp 범위, If-Match 설명, 중복 quarterId 복구)은 **원문 그대로** 가져간다 — 그 이유가 코드에서 드러나지 않는다.

옮길 때 바뀌는 부분은 셋뿐이다.

1. `entry.records` → 파라미터 `records`, `positions` → 파라미터.
2. `modelContext` → 파라미터 `context`, `NetworkService.provider` → `provider ?? NetworkService.provider`(검증에서 가짜 Provider를 넣기 위해).
3. 제출 식별자 결정을 `mode`로 나눈다.

```swift
        let firstRecord = records[0]
        switch mode {
        case .firstSubmission:
            if firstRecord.submissionIdempotencyKey == nil {
                firstRecord.submissionIfMatch = try await latestVersion(matchId: matchId, provider: provider)
                firstRecord.submissionIdempotencyKey = UUID()
                try context.save()
            }
        case .resubmission:
            // 이슈 #96: 운동장이 바뀐 재전송 — 서버가 기존 제출을 그대로 돌려주지 않게
            // 새 Idempotency-Key를 쓰고, 분석 저장으로 올라간 최신 version을 다시 읽는다.
            firstRecord.submissionIfMatch = try await latestVersion(matchId: matchId, provider: provider)
            firstRecord.submissionIdempotencyKey = UUID()
            try context.save()
        }
```

`latestVersion`은 기존 블록을 그대로 함수로 뺀 것이다.

```swift
    /// 서버에 아직 등록되지 않은 경기는 버전을 모르니 nil(= If-Match 헤더 생략)을 쓴다.
    private static func latestVersion(matchId: UUID, provider: (any Provider)?) async throws -> String? {
        let provider = provider ?? NetworkService.provider
        do {
            let detail = try await provider.request(with: MatchEndpoints.detail(matchId: matchId))
            return String(detail.data.version)
        } catch NetworkError.invalidHttpStatusCode(404, _) {
            return nil
        }
    }
```

- [ ] **Step 2: 호출부를 바꾼다**

`ReadyForDetailView.saveAndAnalyze` 안의 `try await submitWorkouts()`를 다음으로 바꾼다.

```swift
                    try await WorkoutSubmissionStore.submit(
                        records: entry.records,
                        positions: positions,
                        mode: .firstSubmission,
                        context: modelContext
                    )
```

- [ ] **Step 3: 빌드 확인**

Run: `cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: BUILD SUCCEEDED

Run: `grep -n "NetworkService\|Endpoints" KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift`
Expected: 결과 없음 — 뷰에 남은 네트워크 호출이 없다.

- [ ] **Step 4: 커밋**

```bash
git add KIIKICK/KIIKICK/Respository/WorkoutSubmissionStore.swift KIIKICK/KIIKICK/Features/View/Analysis/ReadyForDetailView.swift
git commit -m "[refactor] 경기 제출 네트워킹을 스토어로 분리"
```

---

### Task 5: `FieldServerSync` — 재전송(B) 시도, `PATCH /matches`(A) 폴백

**Files:**
- Create: `KIIKICK/KIIKICK/Respository/FieldServerSync.swift`
- Test: `Tests/FieldServerSyncChecks.swift`, `scripts/validation/check-field-server-sync.sh`

**Interfaces:**
- Consumes: Task 4의 `WorkoutSubmissionStore.submit(records:positions:mode:context:provider:)`, `VenueStore.ensureUploaded(_:context:)`, `MatchEndpoints.detail(matchId:)`, `MatchEndpoints.update(matchId:title:venueId:venueSnapshot:scheduledAt:ifMatch:)`, `VenueSnapshot(name:address:)`
- Produces:
  - `enum FieldServerSync`
    - `enum Outcome: Equatable { case skippedNotSubmitted, skippedMatchMissing, resubmitted, matchPatched }`
    - `static func sync(records: [WorkoutRecord], positions: [String], field: Field, context: ModelContext, provider: (any Provider)? = nil) async throws -> Outcome`

- [ ] **Step 1: 실패하는 검증 작성**

`Tests/FieldServerSyncChecks.swift`는 `Tests/VenueChecks.swift`의 `VenueQueuedSession`(응답을 큐로 돌려주고 요청을 기록하는 가짜 `URLSessionable`)을 같은 모양으로 복제해 쓴다. 다섯 경우를 단정한다.

```swift
        // 1. 미제출 경기: 서버 호출이 전혀 없다.
        let notSubmitted = try await FieldServerSync.sync(
            records: [fresh], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(notSubmitted == .skippedNotSubmitted)
        precondition(session.requests.isEmpty)

        // 2. 서버에 없는 경기(detail 404): 로컬만 바꾸고 끝난다.
        submitted.submissionIdempotencyKey = UUID()
        session.replies = [(404, errorBody())]
        let missing = try await FieldServerSync.sync(
            records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(missing == .skippedMatchMissing)

        // 3. B 성공: 새 Idempotency-Key와 최신 If-Match로 재전송된다.
        let previousKey = submitted.submissionIdempotencyKey
        session.replies = [(200, matchDetail(version: 7)), (200, submissionReceipt())]
        let resubmitted = try await FieldServerSync.sync(
            records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(resubmitted == .resubmitted)
        let submitRequest = session.requests.last!
        precondition(submitRequest.url!.path.hasSuffix("/workout-submissions"))
        precondition(submitRequest.value(forHTTPHeaderField: "If-Match") == "7")
        precondition(submitRequest.value(forHTTPHeaderField: "Idempotency-Key") != previousKey?.uuidString)
        let body = try JSONSerialization.jsonObject(with: submitRequest.httpBody!) as! [String: Any]
        let quarters = body["quarters"] as! [[String: Any]]
        let workout = quarters[0]["workout"] as! [String: Any]
        precondition((workout["field"] as! [String: Any])["name"] as! String == "B구장")

        // 4. B 실패(409) → A 폴백: PATCH /matches에 venueId가 실린다.
        session.requests.removeAll()
        session.replies = [(200, matchDetail(version: 8)), (409, errorBody()), (200, matchDetail(version: 9))]
        let patched = try await FieldServerSync.sync(
            records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(patched == .matchPatched)
        let patch = session.requests.last!
        precondition(patch.httpMethod == "PATCH")
        precondition(patch.value(forHTTPHeaderField: "If-Match") == "8")
        let patchBody = try JSONSerialization.jsonObject(with: patch.httpBody!) as! [String: Any]
        precondition(patchBody["venueId"] as! String == fieldB.serverID!.uuidString.lowercased())

        // 5. 둘 다 실패: 에러가 올라오고 제출 식별자는 원래대로 돌아온다.
        let keyBeforeFailure = submitted.submissionIdempotencyKey
        let ifMatchBeforeFailure = submitted.submissionIfMatch
        session.replies = [(200, matchDetail(version: 10)), (409, errorBody()), (412, errorBody())]
        do {
            _ = try await FieldServerSync.sync(
                records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
            preconditionFailure("실패가 전달되지 않았습니다")
        } catch {
            precondition(submitted.submissionIdempotencyKey == keyBeforeFailure)
            precondition(submitted.submissionIfMatch == ifMatchBeforeFailure)
        }
```

고정 응답 본문은 `VenueChecks`의 `venueEnvelope`/`errorBody`와 같은 방식으로 만든다. `matchDetail(version:)`은 `MatchResponse`가 디코딩할 수 있는 최소 필드를, `submissionReceipt()`는 `{"data":{"matchId":…,"quarterCount":1},"meta":{…}}`를 담는다. **`MatchResponse`/`MatchResultEnvelope`의 실제 필수 필드를 `KIIKICK/KIIKICK/Respository/Network/DTO/MatchDTO.swift`에서 확인한 뒤** JSON을 채운다 — 빠진 필드가 있으면 디코딩 실패로 검증이 엉뚱한 곳에서 터진다.

`fieldB`는 `serverID`가 필요하다. `ensureUploaded`가 네트워크를 타지 않도록 `fieldB.serverID`를 미리 채워 둔다(그래서 1번 케이스의 "호출 없음" 단정이 성립한다). venues 업로드 경로는 `check-venues.sh`가 이미 덮는다.

`scripts/validation/check-field-server-sync.sh`는 `check-venues.sh`를 복제해 다음을 추가로 컴파일한다: `"$app"/Data/WorkoutRecord.swift`, `"$global"`의 `TrackPoint,HeartRateSample,MatchEvent,WorkoutPayload,Position`, `"$network"`/API의 `MatchEndpoints,QuarterWorkoutEndpoints`, `"$network"`/DTO의 `MatchDTO,MatchResultDTO,QuarterWorkoutDTO`, `"$app"`/Respository의 `VenueStore,WorkoutSubmissionStore,FieldServerSync`. `chmod +x` 한다.

- [ ] **Step 2: 실패를 확인한다**

Run: `./scripts/validation/check-field-server-sync.sh`
Expected: 컴파일 실패 — `cannot find 'FieldServerSync' in scope`

- [ ] **Step 3: 최소 구현**

```swift
//
//  FieldServerSync.swift
//  KIIKICK
//
//  이슈 #96: 이미 제출된 경기의 운동장이 바뀌었을 때 서버 값을 맞춘다.
//
//  쿼터 리소스에는 venue 필드가 없고 운동장은 workout.field(WorkoutPayload)에만
//  붙는다. 이미 제출된 쿼터의 field만 바꾸는 전용 엔드포인트가 없어서 두 단계로 간다.
//    B) workout-submissions 재전송 — 쿼터별 field까지 맞지만, 서버가 중복 제출을
//       막거나 쿼터를 또 만들 수 있어 동작 확인이 필요하다(이슈 #96).
//    A) PATCH /matches venueId — 공식 API. 경기 대표 운동장만 맞고 쿼터
//       workout.field는 옛 값으로 남는다.
//  B가 어떤 이유로든 실패하면 A로 떨어지고, 둘 다 실패하면 로컬 수정은 그대로 두고
//  호출부가 "서버 반영 실패"를 안내한다.
//

import Foundation
import OSLog
import SwiftData

@MainActor
enum FieldServerSync {
    private static let logger = Logger(subsystem: "KIIKICK", category: "FieldServerSync")

    enum Outcome: Equatable {
        /// 아직 제출된 적 없는 경기 — 바뀐 운동장은 첫 제출에 실려 간다.
        case skippedNotSubmitted
        /// 서버에 등록되지 않은 경기(detail 404) — 로컬 수정만 남긴다.
        case skippedMatchMissing
        case resubmitted
        case matchPatched
    }

    static func sync(
        records: [WorkoutRecord],
        positions: [String],
        field: Field,
        context: ModelContext,
        provider: (any Provider)? = nil
    ) async throws -> Outcome {
        guard let firstRecord = records.first else { throw NetworkError.emptyData }
        guard firstRecord.submissionIdempotencyKey != nil else { return .skippedNotSubmitted }
        let provider = provider ?? NetworkService.provider
        let matchId = firstRecord.matchId

        try await VenueStore.ensureUploaded(field, context: context)

        let version: Int
        do {
            let detail = try await provider.request(with: MatchEndpoints.detail(matchId: matchId))
            version = detail.data.version
        } catch NetworkError.invalidHttpStatusCode(404, _) {
            return .skippedMatchMissing
        }

        let previousKey = firstRecord.submissionIdempotencyKey
        let previousIfMatch = firstRecord.submissionIfMatch
        do {
            try await WorkoutSubmissionStore.submit(
                records: records, positions: positions,
                mode: .resubmission, context: context, provider: provider
            )
            return .resubmitted
        } catch {
            logger.debug("운동장 재전송 실패, PATCH /matches로 폴백: \(error.localizedDescription, privacy: .public)")
            firstRecord.submissionIdempotencyKey = previousKey
            firstRecord.submissionIfMatch = previousIfMatch
            try context.save()
        }

        guard let venueID = field.serverID else { throw NetworkError.emptyData }
        _ = try await provider.request(with: MatchEndpoints.update(
            matchId: matchId,
            venueId: venueID,
            venueSnapshot: VenueSnapshot(name: field.name, address: field.address),
            ifMatch: String(version)
        ))
        return .matchPatched
    }
}
```

`WorkoutSubmissionStore.submit`이 `.resubmission`에서 `MatchEndpoints.detail`을 한 번 더 부르므로, 검증의 응답 큐 순서(`matchDetail` → `matchDetail` → 제출)와 맞는지 확인한다. 중복 조회를 없애려면 `submit`에 이미 읽은 `ifMatch: String?`를 넘기는 오버로드를 두고, 검증의 응답 큐도 같이 줄인다.

- [ ] **Step 4: 통과를 확인한다**

Run: `./scripts/validation/check-field-server-sync.sh`
Expected: `FieldServerSyncChecks 통과`

- [ ] **Step 5: 커밋**

```bash
git add KIIKICK/KIIKICK/Respository/FieldServerSync.swift Tests/FieldServerSyncChecks.swift scripts/validation/check-field-server-sync.sh
git commit -m "[feat] 제출된 경기의 운동장 서버 반영 추가"
```

---

### Task 6: AnalysisDetailView에 운동장 변경 붙이기

**Files:**
- Modify: `KIIKICK/KIIKICK/Features/View/Analysis/AnalysisDetailView.swift:20-45`(상태/init), `:74-140`(body/네비게이션), `:165-300`(`AnalysisTabContent`)

**Interfaces:**
- Consumes: Task 1의 `FieldAssignment`, Task 2의 `FieldChangeRow`, Task 5의 `FieldServerSync.sync(records:positions:field:context:provider:)`
- Produces: 없음

- [ ] **Step 1: 상태 추가**

```swift
    @State private var assignment: FieldAssignment
    @State private var pendingField: Field?
    @State private var isPresentingFieldPicker = false
    @State private var isSyncingField = false
    @State private var fieldSyncError: String?
```

`init`에 추가한다.

```swift
        _assignment = State(initialValue: FieldAssignment(
            quarters: entry.detail.quarters.map {
                FieldAssignment.QuarterInput(id: $0.id, record: $0.sourceRecord, field: $0.field)
            }
        ))
```

- [ ] **Step 2: `AnalysisTabContent`에 행과 오버레이를 넘긴다**

`AnalysisTabContent`에 프로퍼티를 추가한다.

```swift
    let fieldForCurrentQuarter: Field?
    /// 이슈 #96: 로컬 기록이 없는(서버 복원) 엔트리나 친구 경기는 nil — 행을 숨긴다.
    var onChangeField: (() -> Void)?
    let isSyncingField: Bool
```

`positionRow` 아래에 행을 넣고, 히트맵은 오버레이 운동장을 쓰게 한다.

```swift
                    if let position = quarter.position {
                        positionRow(position)
                    }
                    if let onChangeField {
                        HStack(spacing: 8) {
                            FieldChangeRow(field: fieldForCurrentQuarter, action: onChangeField)
                            if isSyncingField { ProgressView().tint(.mint500) }
                        }
                        .disabled(isSyncingField)
                    }
                    heatmapCarousel(quarter, friendHeatmapModel: friendHeatmapModel)
```

`heatmapCarousel`의 `TrackingMapPager(field: quarter.field, …)`를 `TrackingMapPager(field: fieldForCurrentQuarter, …)`로 바꾼다. 친구 히트맵 분기(`friendHeatmap`)는 건드리지 않는다 — 친구 경기엔 `onChangeField`가 nil이고 운동장도 서버 값을 그대로 쓴다.

호출부에서 값을 넘긴다.

```swift
            fieldForCurrentQuarter: currentQuarter.flatMap { assignment.field(for: $0.id) },
            onChangeField: (friendNickname == nil && assignment.isEditable) ? {
                isPresentingFieldPicker = true
            } : nil,
            isSyncingField: isSyncingField,
```

- [ ] **Step 3: 선택·적용·서버 동기화 연결**

```swift
        .navigationDestination(isPresented: $isPresentingFieldPicker) {
            FieldListView(onFieldSelected: handlePickedField)
        }
        .confirmationDialog(
            "이 운동장을 어디에 적용할까요?",
            isPresented: Binding(get: { pendingField != nil }, set: { if !$0 { pendingField = nil } }),
            titleVisibility: .visible
        ) {
            Button("모든 쿼터에 적용") { applyPendingField(to: .allQuarters) }
            if let quarterID = currentQuarter?.id {
                Button("이 쿼터만") { applyPendingField(to: .quarter(quarterID)) }
            }
            Button("취소", role: .cancel) { pendingField = nil }
        }
        .alert("서버에 반영하지 못했어요", isPresented: Binding(
            get: { fieldSyncError != nil }, set: { if !$0 { fieldSyncError = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("운동장은 이 기기에 저장됐어요. 네트워크가 돌아오면 다시 시도해주세요.\n\(fieldSyncError ?? "")")
        }
```

```swift
    private func handlePickedField(_ field: Field) {
        guard entry.detail.quarters.count > 1 else {
            applyField(field, to: .allQuarters)
            return
        }
        pendingField = field
    }

    private func applyPendingField(to scope: FieldAssignmentScope) {
        guard let field = pendingField else { return }
        pendingField = nil
        applyField(field, to: scope)
    }

    /// 로컬 저장이 먼저고, 서버 반영은 실패해도 로컬 수정을 되돌리지 않는다.
    private func applyField(_ field: Field, to scope: FieldAssignmentScope) {
        do {
            try assignment.apply(field, to: scope, save: { try modelContext.save() })
        } catch {
            fieldSyncError = error.localizedDescription
            return
        }
        let targets = assignment.targetQuarterIDs(for: scope)
        let quarters = targets.compactMap { id in entry.detail.quarters.first { $0.id == id } }
        let records = quarters.compactMap(\.sourceRecord)
        let positions = quarters.compactMap { $0.position?.uppercased() }
        guard records.count == quarters.count, positions.count == quarters.count, !records.isEmpty else { return }
        isSyncingField = true
        Task {
            defer { isSyncingField = false }
            do {
                _ = try await FieldServerSync.sync(
                    records: records, positions: positions, field: field, context: modelContext)
            } catch {
                fieldSyncError = error.localizedDescription
            }
        }
    }
```

`.quarter` 범위로 재전송할 때는 그 쿼터 하나만 `records`에 담긴다. 서버가 "제출에 포함되지 않은 쿼터"를 어떻게 처리하는지는 Task 7의 확인 항목이다 — 누락/중복이 생기면 재전송은 항상 경기 전체를 보내도록 `records`를 `entry.records`, `positions`를 전체 쿼터의 포지션으로 바꾼다.

- [ ] **Step 4: 빌드와 검증**

Run: `cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: BUILD SUCCEEDED

Run: `./scripts/validation/check-field-assignment.sh && ./scripts/validation/check-field-server-sync.sh && ./scripts/check-overall.sh`
Expected: 전부 통과

- [ ] **Step 5: 시뮬레이터 수동 확인**

(1) 분석 상세에서 운동장 행이 보이고 변경이 되는지, (2) 변경 직후 히트맵이 새 운동장으로 다시 그려지는지, (3) 친구 경기 상세에는 행이 **안** 보이는지, (4) 비행기 모드에서 서버 반영이 실패해도 로컬 수정이 유지되고 알림이 뜨는지 확인한다.

- [ ] **Step 6: 커밋**

```bash
git add KIIKICK/KIIKICK/Features/View/Analysis/AnalysisDetailView.swift
git commit -m "[feat] 분석 상세에서 운동장 변경 지원"
```

---

### Task 7: 실제 서버에서 재전송 가능성 확인

이슈 #96의 "서버에 이미 전송이 되어 있는 경우에는 재전송이 가능한 지 테스트해볼 것" 항목이다. 가짜 Provider로는 **서버가 중복 제출을 어떻게 처리하는지** 알 수 없으므로 dev 계정으로 직접 확인한다.

- [ ] **Step 1: 제출된 경기를 하나 만든다**

`DevAuthView`("로그인 화면 보기")로 로그인한 뒤 경기를 기록하고 분석 보기까지 진행해, `workout-submissions`가 성공하는 것을 Console(`subsystem:KIIKICK category:WorkoutSubmission`)에서 확인한다.

- [ ] **Step 2: 운동장을 바꿔 재전송을 관찰한다**

분석 상세에서 운동장을 다른 값으로 바꾸고 다음을 기록한다.
- `workout-submissions` 재전송의 HTTP 상태 코드
- 성공했다면 `GET /matches/{id}/quarter-results`의 쿼터 개수가 **늘지 않았는지**(중복 생성 여부)
- 성공했다면 `ResultWorkout.field.name`이 새 운동장으로 바뀌었는지
- 실패했다면 상태 코드와 `PATCH /matches` 폴백이 성공했는지

- [ ] **Step 3: 결과에 따라 코드를 확정한다**

- **갱신되고 쿼터도 늘지 않으면**: B 경로 유지. `FieldServerSync.swift` 상단 주석에 확인 결과와 날짜를 적는다.
- **409/412로 막히면**: B는 폴백 경로로만 남기고(코드는 그대로), 주석에 "서버가 재전송을 거부함 — A가 사실상 유일한 경로"를 적는다.
- **쿼터가 중복 생성되면**: `FieldServerSync.sync`에서 B 시도를 제거하고 바로 A로 간다. `WorkoutSubmissionStore.Mode.resubmission`과 `Tests/FieldServerSyncChecks.swift`의 3·4번 케이스도 함께 지운다.

- [ ] **Step 4: 기록하고 커밋**

```bash
gh issue comment 96 --body "재전송 확인 결과: <상태 코드 / 쿼터 개수 / field 반영 여부>"
git add -A
git commit -m "[docs] 운동장 재전송 서버 동작 확인 결과 반영"
```

- [ ] **Step 5: PR**

최신 `main`을 먼저 머지하고 빌드가 깨지지 않는지 확인한 뒤 `main`으로 PR을 연다.

```bash
git fetch origin
git merge origin/main
cd KIIKICK && xcodebuild -scheme KIIKICK -destination 'generic/platform=iOS Simulator' -configuration Debug build
```
