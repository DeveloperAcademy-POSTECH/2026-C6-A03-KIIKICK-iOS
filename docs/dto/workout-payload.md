# WorkoutPayload DTO

Apple Watch에서 측정이 끝나면 iPhone으로 전송되는 데이터 구조입니다. Swift에서는 `KIIKICK/KIIKICK Global/WorkoutPayload.swift`에 정의되어 있고, `Codable`로 JSON 인코딩/디코딩됩니다.

## 전송 방식

- Watch → iPhone: `WCSession.transferFile`로 JSON 파일 1개를 전송 (측정 1회 = 파일 1개).
- 지금은 iPhone만 이 파일을 받아서 처리합니다. 서버로 올리는 경로는 아직 없고, 이 문서는 iPhone이 들고 있는 데이터 구조를 서버와 맞추기 위한 것입니다.

## ⚠️ `timestamp` / `startDate` / `endDate` 날짜 인코딩 주의

Swift `JSONEncoder` 기본 설정(`dateEncodingStrategy` 미지정)은 `Date`를 **2001-01-01T00:00:00Z를 기준(epoch)으로 한 초 단위 `Double`**로 인코딩합니다. 일반적인 Unix epoch(1970-01-01)가 아닙니다.

- Unix epoch로 바꾸려면: `unixTimestamp = appleTimestamp + 978307200` (2001-01-01과 1970-01-01의 초 차이)
- 서버에서 ISO8601 문자열 등 다른 포맷을 원하면, iOS/watchOS 쪽에서 `JSONEncoder.dateEncodingStrategy`를 바꿔서 맞출 수 있습니다. 지금은 기본값(위 Apple epoch 숫자) 그대로 사용 중입니다.

## WorkoutPayload (최상위 객체)

| 필드 | 타입 | 단위 | 설명 |
|---|---|---|---|
| `startDate` | Date (숫자) | - | 측정 시작 시각 |
| `endDate` | Date (숫자) | - | 측정 종료 시각 |
| `points` | `[TrackPoint]` | - | 측정 중 수집된 GPS 포인트, 시간순 |
| `heartRateSamples` | `[HeartRateSample]` | - | 측정 중 수집된 심박수 샘플, 시간순 |
| `totalCalories` | Double | kcal | 측정 종료 시점까지 누적된 활동 칼로리 (HealthKit `activeEnergyBurned` 누적값) |
| `totalDistance` | Double | m | 측정 종료 시점까지 누적된 이동 거리 (HealthKit `distanceWalkingRunning` 누적값) |

## TrackPoint (GPS 포인트 1개)

`CLLocation`에서 그대로 가져온 값입니다.

| 필드 | 타입 | 단위 | 설명 |
|---|---|---|---|
| `latitude` | Double | degrees | 위도 |
| `longitude` | Double | degrees | 경도 |
| `altitude` | Double | m | 고도 |
| `horizontalAccuracy` | Double | m | 위치 정확도 반경 (작을수록 정확) |
| `speed` | Double | m/s | 순간 속도. 값이 유효하지 않으면 `-1` |
| `course` | Double | degrees (0~359.9, 정북 기준) | 이동 방향. 값이 유효하지 않으면 `-1` |
| `timestamp` | Date (숫자) | - | 이 위치가 측정된 시각 |

워치에서는 `CLLocationManager.distanceFilter = 1`로 설정되어 있어, **직전 포인트에서 1m 이상 이동했을 때만** 새 `TrackPoint`가 생성됩니다.

## HeartRateSample (심박수 샘플 1개)

| 필드 | 타입 | 단위 | 설명 |
|---|---|---|---|
| `timestamp` | Date (숫자) | - | 측정 시각 |
| `bpm` | Double | bpm (분당 박동수) | 심박수 |

## 예시 JSON

```json
{
  "startDate": 750000000.0,
  "endDate": 750000600.0,
  "totalCalories": 420.5,
  "totalDistance": 3182.4,
  "points": [
    {
      "latitude": 37.5665,
      "longitude": 126.9780,
      "altitude": 20.1,
      "horizontalAccuracy": 4.8,
      "speed": 2.3,
      "course": 87.5,
      "timestamp": 750000001.2
    }
  ],
  "heartRateSamples": [
    { "timestamp": 750000001.0, "bpm": 142.0 },
    { "timestamp": 750000006.0, "bpm": 145.0 }
  ]
}
```

## 참고: iPhone에서의 저장 형태

iPhone에서는 받은 payload를 그대로 SwiftData 모델(`WorkoutRecord`)에 옮겨 저장합니다. 필드 구성은 `WorkoutPayload`와 거의 동일하며, `startDate`/`endDate` 대신 `date`(= `startDate`)와 `duration`(= `endDate - startDate`, 초)으로 변환해서 들고 있습니다.
