# Workout Tracking (Watch → iPhone) Design

## Overview

Watch 앱에서 측정을 시작하면 CoreLocation + HealthKit으로 위치/심박수/칼로리/거리/시간을 수집한다. 측정을 종료하면 수집한 데이터를 WatchConnectivity 파일 전송으로 iPhone에 보낸다. iPhone은 받은 데이터를 SwiftData에 저장하고, 기록 List → 상세 화면(지도 + 통계 + 심박수 그래프)으로 보여준다.

## Watch

- `WorkoutManager`가 `CLLocationManager`를 소유. `distanceFilter = 1`(미터)로 설정해서 1m 이상 이동했을 때만 위치 업데이트가 들어오게 한다.
- "측정 시작": 위치 권한 요청 → `HKWorkoutSession`/`HKLiveWorkoutBuilder` 시작 → 위치 업데이트 시작.
- 위치 업데이트가 들어올 때마다 `TrackPoint(latitude, longitude, timestamp)`를 배열에 순서대로 append.
- `HKLiveWorkoutBuilder`의 `didCollectDataOf`에서 심박수가 들어올 때마다 현재 값만 덮어쓰는 대신 `HeartRateSample(timestamp, bpm)`을 시계열 배열에 append.
- "측정 종료": 위치 업데이트/워크아웃 세션 종료. `activeEnergy`/`distance`는 이미 HealthKit `sumQuantity()`로 누적된 값이므로 종료 시점의 값을 그대로 `totalCalories`/`totalDistance`로 사용. 총 시간은 종료 시각 - 시작 시각.
- 기존 `heartRate`/`activeEnergy`/`distance`/`speed` 프로퍼티(현재 값 스냅샷)는 그대로 두고, 심박수 시계열만 별도 배열로 추가 기록한다.
- 측정 종료 시 아래 payload를 JSON으로 인코딩해 임시 파일에 쓰고, `WCSession.transferFile`로 전송 (`SessionManager`에 이미 있는 `transferStatus`/`didFinish fileTransfer` 틀 사용).

```swift
struct WorkoutPayload: Codable {
    let startDate: Date
    let endDate: Date
    let points: [TrackPoint]
    let heartRateSamples: [HeartRateSample]
    let totalCalories: Double
    let totalDistance: Double
}
struct TrackPoint: Codable { let latitude: Double; let longitude: Double; let timestamp: Date }
struct HeartRateSample: Codable { let timestamp: Date; let bpm: Double }
```

## Transfer

- 전송 방식: `WCSession.default.transferFile(url:metadata:)`. 측정이 끝난 뒤 한 번만 보내면 되고, 앱이 꺼져 있어도 큐에 남아 재시도되는 파일 전송이 메시지 전송보다 적합하다.
- iPhone 쪽 `SessionManager.session(_:didReceive:file:)`에서 파일을 읽어 `WorkoutPayload`로 디코딩.

## iPhone — 저장

```swift
@Model final class WorkoutRecord {
    var date: Date
    var duration: TimeInterval
    var totalCalories: Double
    var totalDistance: Double
    var points: [TrackPoint]
    var heartRateSamples: [HeartRateSample]
}
```

- `SessionManager`가 받은 파일을 디코딩해 `WorkoutRecord`로 변환하고, 공유 `ModelContainer`의 `ModelContext`에 insert + save.

## iPhone — UI

- **List 화면**: `@Query`로 모든 `WorkoutRecord`를 날짜 내림차순으로 조회해 리스트로 표시 (날짜, 거리/시간 정도를 행에 요약).
- **Detail 화면** (List에서 행 선택 시 이동, 한 화면 스크롤):
  - 상단: `Map` + 번호 붙은 핀(1, 2, 3 ...)으로 `points`를 순서대로 표시.
  - 중단: 칼로리 / 거리 / 시간 스탯 타일.
  - 하단: 심박수 시계열 라인 그래프 (Swift Charts).

## 개발 단계 (단계마다 빌드 확인 후 git commit)

1. Watch: 1m 필터 위치 수집 + ContentView에 측정 시작/종료 버튼, 수집된 포인트 수 표시
2. Watch: 심박수 시계열 기록 + 종료 시 칼로리/거리/시간 요약 계산
3. Watch→iPhone: 측정 종료 시 payload를 JSON 파일로 인코딩해 `WCSession.transferFile` 전송
4. iPhone: SwiftData 모델(`WorkoutRecord`/`TrackPoint`/`HeartRateSample`) 정의 + 파일 수신 시 저장
5. iPhone: 기록 List 화면
6. iPhone: Detail 화면 — 지도(번호 핀) + 통계 타일 + 심박수 그래프 (한 화면 스크롤)

## 범위 밖 (Out of scope)

- 백그라운드에서 화면이 잠긴 동안 측정을 이어가는 것(`workout-processing` 백그라운드 모드)은 이번 범위에 포함하지 않음. 필요해지면 별도로 추가.
- 기록 삭제/수정 UI는 포함하지 않음 (저장 + 조회만).
