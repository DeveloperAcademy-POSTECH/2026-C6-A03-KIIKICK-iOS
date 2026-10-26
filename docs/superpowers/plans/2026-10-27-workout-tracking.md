# Workout Tracking (Watch → iPhone) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Watch에서 1m 간격 위치 + 심박수/칼로리/거리를 측정하고, 종료 시 iPhone으로 전송해 SwiftData에 저장하고 List → Detail(지도+통계+그래프) 화면으로 보여준다.

**Architecture:** Watch의 `WorkoutManager`가 `CLLocationManager`(distanceFilter=1m)와 `HKWorkoutSession`/`HKLiveWorkoutBuilder`로 데이터를 모은다. 측정 종료 시 `WorkoutPayload`(Codable)로 묶어 `SessionManager`를 통해 `WCSession.transferFile`로 iPhone에 보낸다. iPhone의 `SessionManager`가 파일을 받아 디코딩하고 SwiftData `WorkoutRecord`로 저장한다. iPhone `ContentView`는 `@Query`로 기록 List를 보여주고, 행을 누르면 `WorkoutDetailView`(지도+통계+심박수 그래프)로 이동한다.

**Tech Stack:** SwiftUI, CoreLocation, HealthKit (HKWorkoutSession/HKLiveWorkoutBuilder), WatchConnectivity, SwiftData, MapKit (`Map`/`Marker`), Swift Charts.

## Global Constraints

- 이 프로젝트에는 XCTest 타겟이 없다(`xcodebuild -list` 확인됨). 새 테스트 타겟을 만드는 것은 이 플랜의 범위 밖이므로, 각 태스크의 검증은 **`xcodebuild build` 성공 + 시뮬레이터/기기에서 직접 눌러보는 수동 확인**으로 한다. "실패하는 테스트를 먼저 작성" 단계는 생략한다.
- 기존 코드 스타일을 따른다: `@Observable final class X: NSObject`, 플랫폼 분기는 `#if os(watchOS)` / `#if os(iOS)`, 상태 변경은 `DispatchQueue.main.async { ... }`로 감싼다 (`KIIKICK Global/SessionManager.swift` 참고).
- 번들 ID: iOS `com.seungjunlee.KIIKICK`, watch `com.seungjunlee.KIIKICK.watchkitapp`. 팀 `2QJX795Q3R`.
- 시뮬레이터 빌드/실행 확인용 watchOS 시뮬레이터 디바이스 ID: `8D028A03-1C28-49AA-9A5B-6179B9EB7626` (Apple Watch Series 11 46mm). 없으면 `xcrun simctl list devices available | grep -i watch`로 다시 확인.
- 새 파일은 각각 올바른 fileSystemSynchronizedGroup 폴더 밑에 만들면 Xcode가 자동으로 타겟에 포함한다 (`KIIKICK Global/` = 양쪽 타겟 공용, `KIIKICK/` = iOS 전용, `KIIKICK Watch App Watch App/` = watch 전용). pbxproj를 직접 건드릴 일은 Info.plist 키 추가뿐이다.
- 매 태스크 끝에 `git add` + `git commit` (커밋 메시지는 한국어, 기존 커밋 스타일 `[feat] ...` 따름).

---

### Task 1: Watch — 1m 위치 수집 + 측정 시작/종료 버튼

**Files:**
- Modify: `KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift`
- Modify: `KIIKICK/KIIKICK Watch App Watch App/ContentView.swift`
- Modify: `KIIKICK/KIIKICK.xcodeproj/project.pbxproj` (watch 타겟 Debug/Release 빌드 설정 2곳)

**Interfaces:**
- Produces: `WorkoutManager.isRunning: Bool`, `WorkoutManager.points: [TrackPoint]` (읽기 전용), `WorkoutManager.start() async`, `WorkoutManager.stop() async`, `CLLocationManagerDelegate` 채택.
- `TrackPoint`는 이 태스크에서 `WorkoutManager.swift` 안에 임시로 정의한다 (Task 3에서 `KIIKICK Global/WorkoutPayload.swift`로 옮긴다).

- [ ] **Step 1: `WorkoutManager`에 위치 수집 추가**

`KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift` 전체를 아래로 교체:

```swift
//
//  WorkoutManager.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/27/26.
//

import HealthKit
import CoreLocation
import Foundation

struct TrackPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

@Observable
final class WorkoutManager: NSObject {

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let locationManager = CLLocationManager()

    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var distance: Double = 0
    var speed: Double = 0

    var isRunning: Bool = false
    private(set) var points: [TrackPoint] = []

    func start() async {
        await requestAuthorization()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.requestWhenInUseAuthorization()

        let config = HKWorkoutConfiguration()
        config.activityType = .soccer
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder
            points = []

            let startDate = Date()
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)

            isRunning = true
            locationManager.startUpdatingLocation()
        } catch {
            print("[WorkoutManager] 세션 시작 실패 - \(error)")
        }
    }

    func stop() async {
        locationManager.stopUpdatingLocation()

        guard let session = workoutSession, let builder = workoutBuilder else {
            isRunning = false
            return
        }

        let endDate = Date()
        session.stopActivity(with: endDate)
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
        } catch {
            print("[WorkoutManager] 세션 종료 실패 - \(error)")
        }

        isRunning = false
    }

    // MARK: - Private Helpers

    private func requestAuthorization() async {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.runningSpeed),
        ]
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.runningSpeed),
        ]
        try? await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
        print("[WorkoutManager] session 오류: \(error)")
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            switch quantityType {
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                DispatchQueue.main.async { self.heartRate = value }
            case HKQuantityType(.activeEnergyBurned):
                let value = workoutBuilder.statistics(for: quantityType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                DispatchQueue.main.async { self.activeEnergy = value }
            case HKQuantityType(.distanceWalkingRunning):
                let value = workoutBuilder.statistics(for: quantityType)?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                DispatchQueue.main.async { self.distance = value }
            case HKQuantityType(.runningSpeed):
                let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: .meter().unitDivided(by: .second())) ?? 0
                DispatchQueue.main.async { self.speed = value }
            default:
                break
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension WorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let point = TrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp
        )
        DispatchQueue.main.async { self.points.append(point) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[WorkoutManager] 위치 오류 - \(error)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isRunning else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}
```

- [ ] **Step 2: watch `ContentView`에 시작/종료 버튼 + 포인트 수 표시**

`KIIKICK/KIIKICK Watch App Watch App/ContentView.swift` 전체를 아래로 교체:

```swift
//
//  ContentView.swift
//  KIIKICK Watch App Watch App
//

import SwiftUI

struct ContentView: View {
    @State private var workoutManager = WorkoutManager()

    var body: some View {
        VStack(spacing: 12) {
            Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
            Text("\(workoutManager.points.count)개 측정됨")
            Button(workoutManager.isRunning ? "측정 종료" : "측정 시작") {
                Task {
                    if workoutManager.isRunning {
                        await workoutManager.stop()
                    } else {
                        await workoutManager.start()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 3: watch Info.plist에 위치 권한 사용 목적 문자열 추가**

`KIIKICK/KIIKICK.xcodeproj/project.pbxproj`에서 watch 타겟 Debug/Release 설정 둘 다에 `INFOPLIST_KEY_NSHealthShareUsageDescription` 바로 아래에 한 줄 추가 (Debug/Release 두 군데 모두):

```
				INFOPLIST_KEY_NSHealthShareUsageDescription = "운동 중 심박수, 거리, 속도 등 건강 데이터를 가져오기 위해 접근 권한이 필요합니다.";
				INFOPLIST_KEY_NSHealthUpdateUsageDescription = "완료된 운동 기록을 건강 앱에 저장하기 위해 접근 권한이 필요합니다.";
				INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "운동 경로를 1m 단위로 기록하기 위해 위치 접근 권한이 필요합니다.";
```

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK Watch App Watch App" -destination 'id=8D028A03-1C28-49AA-9A5B-6179B9EB7626' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

watchOS 시뮬레이터를 열어서(`open -a Simulator`) 앱을 설치/실행하고 "측정 시작" 버튼을 눌러 위치 권한 다이얼로그가 뜨는지, 버튼이 "측정 종료"로 바뀌는지 확인한다.

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift" "KIIKICK/KIIKICK Watch App Watch App/ContentView.swift" "KIIKICK/KIIKICK.xcodeproj/project.pbxproj"
git commit -m "[feat] Watch 1m 위치 수집 + 측정 시작/종료 버튼"
```

---

### Task 2: Watch — 심박수 시계열 기록 + 종료 시 요약 계산

**Files:**
- Modify: `KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift`

**Interfaces:**
- Consumes: Task 1의 `WorkoutManager.points`, `isRunning`, `start()`/`stop()`.
- Produces: `HeartRateSample` 구조체, `WorkoutManager.heartRateSamples: [HeartRateSample]`, `stop()` 안의 로컬 변수 `startDate` — Task 3에서 `WorkoutPayload` 조립에 그대로 사용.

- [ ] **Step 1: 심박수 시계열 + 요약 추가**

`KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift`에서 `TrackPoint` 구조체 바로 아래에 추가:

```swift
struct HeartRateSample: Codable {
    let timestamp: Date
    let bpm: Double
}
```

`isRunning`/`points` 선언 아래에 추가:

```swift
    private(set) var heartRateSamples: [HeartRateSample] = []
```

`start()`의 `points = []` 바로 아래 줄에 추가:

```swift
            heartRateSamples = []
```

`stop()`의 `let endDate = Date()` 바로 아래, `session.stopActivity` 호출 전에 추가 (Task 3에서 `WorkoutPayload`의 `startDate`로 사용):

```swift
        let startDate = builder.startDate ?? endDate
```

`workoutBuilder(_:didCollectDataOf:)`의 `.heartRate` 케이스를 아래로 교체 (현재 값 덮어쓰기 + 시계열 추가):

```swift
            case HKQuantityType(.heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                guard let value = workoutBuilder.statistics(for: quantityType)?.mostRecentQuantity()?.doubleValue(for: unit) else { break }
                let sample = HeartRateSample(timestamp: Date(), bpm: value)
                DispatchQueue.main.async {
                    self.heartRate = value
                    self.heartRateSamples.append(sample)
                }
```

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK Watch App Watch App" -destination 'id=8D028A03-1C28-49AA-9A5B-6179B9EB7626' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift"
git commit -m "[feat] Watch 심박수 시계열 기록 + 측정 종료 시 요약 계산"
```

---

### Task 3: Watch → iPhone — JSON 파일 전송

**Files:**
- Create: `KIIKICK/KIIKICK Global/WorkoutPayload.swift`
- Modify: `KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift`
- Modify: `KIIKICK/KIIKICK Global/SessionManager.swift`

**Interfaces:**
- Consumes: Task 1/2의 `WorkoutManager.points: [TrackPoint]`, `heartRateSamples: [HeartRateSample]`, `stop()` 안의 `startDate`/`endDate`.
- Produces: `WorkoutPayload` (양쪽 타겟 공용 Codable), `SessionManager.send(payload: WorkoutPayload)` (watchOS 전용).
- `TrackPoint`/`HeartRateSample`를 `WorkoutManager.swift`에서 삭제하고 이 새 파일로 옮긴다 — 두 구조체는 더 이상 `WorkoutManager.swift`에 정의하지 않는다.

- [ ] **Step 1: 공용 Payload 모델 파일 생성**

Create `KIIKICK/KIIKICK Global/WorkoutPayload.swift`:

```swift
//
//  WorkoutPayload.swift
//  KIIKICK Global
//

import Foundation

struct TrackPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

struct HeartRateSample: Codable {
    let timestamp: Date
    let bpm: Double
}

struct WorkoutPayload: Codable {
    let startDate: Date
    let endDate: Date
    let points: [TrackPoint]
    let heartRateSamples: [HeartRateSample]
    let totalCalories: Double
    let totalDistance: Double
}
```

- [ ] **Step 2: `WorkoutManager.swift`에서 중복 구조체 제거 + 종료 시 전송 호출**

`KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift`에서 파일 맨 위의 `struct TrackPoint { ... }`와 `struct HeartRateSample { ... }` 정의 두 블록을 통째로 삭제한다 (Step 1에서 `KIIKICK Global`로 옮겼으므로 중복 선언이 되어 빌드가 깨진다).

`stop()`의 `try await builder.finishWorkout()` 호출이 포함된 `do { ... } catch { ... }` 블록 바로 아래, `isRunning = false` 전에 추가:

```swift
        let payload = WorkoutPayload(
            startDate: startDate,
            endDate: endDate,
            points: points,
            heartRateSamples: heartRateSamples,
            totalCalories: activeEnergy,
            totalDistance: distance
        )
        SessionManager.shared.send(payload: payload)
```

- [ ] **Step 3: `SessionManager`에 watch 쪽 전송 함수 추가**

`KIIKICK/KIIKICK Global/SessionManager.swift`의 `#if os(watchOS)` 블록 안, `beginTransfer(pointCount:)` 함수 바로 아래에 추가:

```swift
    func send(payload: WorkoutPayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            try data.write(to: url)
            beginTransfer(pointCount: payload.points.count)
            WCSession.default.transferFile(url, metadata: nil)
        } catch {
            DispatchQueue.main.async { self.transferStatus = .failure(error.localizedDescription) }
        }
    }
```

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK Watch App Watch App" -destination 'id=8D028A03-1C28-49AA-9A5B-6179B9EB7626' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **` (iOS 쪽은 아직 `didReceive file:`가 비어있지만, `WorkoutPayload`가 양쪽에서 똑같이 컴파일되는지 여기서 같이 확인한다)

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK Global/WorkoutPayload.swift" "KIIKICK/KIIKICK Watch App Watch App/WorkoutManager.swift" "KIIKICK/KIIKICK Global/SessionManager.swift"
git commit -m "[feat] 측정 종료 시 WorkoutPayload를 WCSession.transferFile로 전송"
```

---

### Task 4: iPhone — SwiftData 모델 + 수신 저장

**Files:**
- Create: `KIIKICK/KIIKICK/WorkoutRecord.swift`
- Modify: `KIIKICK/KIIKICK Global/SessionManager.swift`
- Modify: `KIIKICK/KIIKICK/MyApp.swift`

**Interfaces:**
- Consumes: Task 3의 `WorkoutPayload`.
- Produces: `WorkoutRecord`(`@Model`, iOS 전용) — `date: Date`, `duration: TimeInterval`, `totalCalories: Double`, `totalDistance: Double`, `points: [TrackPoint]`, `heartRateSamples: [HeartRateSample]`, `init(payload: WorkoutPayload)`. `SessionManager.modelContext: ModelContext?` (iOS 전용, MyApp이 세팅).

- [ ] **Step 1: `WorkoutRecord` SwiftData 모델 생성**

Create `KIIKICK/KIIKICK/WorkoutRecord.swift`:

```swift
//
//  WorkoutRecord.swift
//  KIIKICK
//

import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var date: Date
    var duration: TimeInterval
    var totalCalories: Double
    var totalDistance: Double
    var points: [TrackPoint]
    var heartRateSamples: [HeartRateSample]

    init(payload: WorkoutPayload) {
        self.date = payload.startDate
        self.duration = payload.endDate.timeIntervalSince(payload.startDate)
        self.totalCalories = payload.totalCalories
        self.totalDistance = payload.totalDistance
        self.points = payload.points
        self.heartRateSamples = payload.heartRateSamples
    }
}
```

- [ ] **Step 2: `SessionManager`에 iOS 쪽 저장 로직 추가**

`KIIKICK/KIIKICK Global/SessionManager.swift` 맨 위 import 목록에 추가:

```swift
import SwiftData
```

`#if os(iOS)` 블록 안, `decodeLocation` 함수를 삭제하고 그 자리에 추가 (더 이상 쓰이지 않는 죽은 코드이므로 제거):

```swift
    var modelContext: ModelContext?
```

`session(_:didReceive:file:)` 함수 전체를 아래로 교체:

```swift
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        #if os(iOS)
        guard let data = try? Data(contentsOf: file.fileURL),
              let payload = try? JSONDecoder().decode(WorkoutPayload.self, from: data) else {
            #if DEBUG
            print("[SessionManager] 수신 파일 디코딩 실패")
            #endif
            return
        }
        let record = WorkoutRecord(payload: payload)
        DispatchQueue.main.async {
            self.modelContext?.insert(record)
            try? self.modelContext?.save()
        }
        #endif
    }
```

- [ ] **Step 3: `MyApp`에서 `ModelContainer` 생성 + `SessionManager`에 연결**

`KIIKICK/KIIKICK/MyApp.swift` 전체를 아래로 교체:

```swift
import SwiftUI
import SwiftData

@main struct MyApp: App {

    let modelContainer: ModelContainer

    init() {
        modelContainer = try! ModelContainer(for: WorkoutRecord.self)
        SessionManager.shared.modelContext = modelContainer.mainContext
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SessionManager.shared)
        }
        .modelContainer(modelContainer)
    }
}
```

- [ ] **Step 4: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: 커밋**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/WorkoutRecord.swift" "KIIKICK/KIIKICK Global/SessionManager.swift" "KIIKICK/KIIKICK/MyApp.swift"
git commit -m "[feat] iPhone에서 수신한 측정 데이터를 SwiftData에 저장"
```

---

### Task 5: iPhone — 기록 List 화면

**Files:**
- Modify: `KIIKICK/KIIKICK/ContentView.swift`

**Interfaces:**
- Consumes: Task 4의 `WorkoutRecord` (`@Model`, `Hashable`/`Identifiable` 자동 합성).
- Produces: `NavigationStack` + `navigationDestination(for: WorkoutRecord.self)` — Task 6의 `WorkoutDetailView`가 이 목적지로 들어간다.

- [ ] **Step 1: `ContentView`를 List + NavigationStack으로 교체**

`KIIKICK/KIIKICK/ContentView.swift` 전체를 아래로 교체:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List(records) { record in
                    NavigationLink(value: record) {
                        VStack(alignment: .leading) {
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            Text("\(Int(record.totalDistance))m · \(Int(record.duration / 60))분")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: WorkoutRecord.self) { record in
                WorkoutDetailView(record: record)
            }
            .navigationTitle("측정 기록")
        }
    }
}
```

(Task 6에서 `WorkoutDetailView`를 만들기 전까지는 이 파일만 두면 "Cannot find 'WorkoutDetailView' in scope" 빌드 에러가 나는 게 정상이다 — Step 2에서 Task 6을 바로 이어서 진행한다.)

- [ ] **Step 2: 커밋 (Task 6과 함께)**

이 태스크는 Task 6의 `WorkoutDetailView` 없이는 빌드되지 않으므로, 빌드 확인과 커밋은 Task 6의 Step에서 두 파일을 같이 묶어서 진행한다. 이 태스크만 따로 커밋하지 않는다.

---

### Task 6: iPhone — Detail 화면 (지도 번호 핀 + 통계 + 심박수 그래프)

**Files:**
- Create: `KIIKICK/KIIKICK/WorkoutDetailView.swift`

**Interfaces:**
- Consumes: Task 4의 `WorkoutRecord`, Task 5의 `navigationDestination(for: WorkoutRecord.self)`.

- [ ] **Step 1: `WorkoutDetailView` 생성**

Create `KIIKICK/KIIKICK/WorkoutDetailView.swift`:

```swift
//
//  WorkoutDetailView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import Charts

struct WorkoutDetailView: View {
    let record: WorkoutRecord

    private var region: MKCoordinateRegion {
        let lats = record.points.map(\.latitude)
        let lngs = record.points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.003) * 1.4,
            longitudeDelta: max(maxLng - minLng, 0.003) * 1.4
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Map(initialPosition: .region(region)) {
                    ForEach(Array(record.points.enumerated()), id: \.offset) { index, point in
                        Marker(
                            "\(index + 1)",
                            coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                        )
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    StatTile(title: "칼로리", value: "\(Int(record.totalCalories)) kcal")
                    StatTile(title: "거리", value: "\(Int(record.totalDistance)) m")
                    StatTile(title: "시간", value: "\(Int(record.duration / 60)) 분")
                }

                Text("심박수")
                    .font(.headline)

                Chart(record.heartRateSamples, id: \.timestamp) { sample in
                    LineMark(
                        x: .value("시간", sample.timestamp),
                        y: .value("BPM", sample.bpm)
                    )
                }
                .frame(height: 160)
            }
            .padding()
        }
        .navigationTitle(record.date.formatted(date: .abbreviated, time: .shortened))
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `cd "KIIKICK" && xcodebuild -scheme "KIIKICK" -destination 'generic/platform=iOS Simulator' -configuration Debug build`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 전체 흐름 수동 확인**

1. watch 앱에서 "측정 시작" → 위치가 조금씩 바뀌는 환경(시뮬레이터면 Debug ▸ Location ▸ City Run/Freeway Drive 등)에서 포인트 수가 올라가는지 확인.
2. "측정 종료" 누르고 iPhone 앱(같은 시뮬레이터 페어 또는 실기기)에서 List에 새 행이 생기는지 확인.
3. 행을 눌러 Detail로 들어가서 지도에 번호 핀, 칼로리/거리/시간 타일, 심박수 그래프가 보이는지 확인.

- [ ] **Step 4: 커밋 (Task 5 + 6)**

```bash
cd "/Users/seungjunlee/Desktop/2026-C6-A03-KIIKICK-iOS"
git add "KIIKICK/KIIKICK/ContentView.swift" "KIIKICK/KIIKICK/WorkoutDetailView.swift"
git commit -m "[feat] 측정 기록 List + 지도/통계/심박수 그래프 Detail 화면"
```
