# 운동장 바꾸기 기능 설계 (이슈 #96)

## 목표

이미 기록된 경기의 운동장을 바꿀 수 있게 한다. ReadyForDetailView(분석 준비)와
AnalysisDetailView(분석 상세) 양쪽에서 가능해야 하고, 이미 서버에 제출된 경기는
서버 값도 함께 갱신한다.

## 현재 상태

- `ReadyForDetailView`: 운동장이 **없는** 쿼터만 `fieldAssignmentNotice`를 통해
  `FieldListView`로 지정할 수 있다. 이미 지정된 운동장을 바꿀 경로가 없고,
  `assignMissingFields`는 비어 있는 쿼터 전부에 한 운동장을 일괄 적용한다.
- `AnalysisDetailView`: 운동장 관련 진입점이 전혀 없다. `hasViewedAnalysis == true`가
  되면 ReadyForDetail을 다시 거치지 않으므로, 분석을 한 번 본 경기는 수정 수단이 없다.
- 서버: `workout-submissions`가 쿼터별 `workout.field`를 함께 보낸다. 재전송을 막는
  요소는 `WorkoutRecord.submissionIdempotencyKey`(재사용 시 서버가 기존 제출을 그대로
  반환할 수 있음)와 `submissionIfMatch`(옛 version → 412)다.

## API 확인 결과

| 범위 | 서버 표현 | 수정 수단 |
|---|---|---|
| 경기(일괄) | `MatchResponse.venueId` / `venueSnapshot` | SET-09 `PATCH /matches/{id}` (body `venueId`, `If-Match` 필수) — 공식 지원 |
| 쿼터별 | 쿼터 리소스에 venue 없음. 운동장은 `workout.field`(`WorkoutPayload` → `ResultWorkout.field`)에만 붙는다 | 제출 시점엔 쿼터마다 다른 `field` 전송 가능. 이미 제출된 쿼터의 field만 바꾸는 전용 엔드포인트는 **없다** → `workout-submissions` 재전송 또는 WORK-01 payload 재업로드뿐이고, 서버가 덮어쓰기를 허용하는지는 미확인 |

즉 쿼터별 변경은 **첫 제출 전에는 확실히 가능**하고, **제출 후에는 서버 동작 확인이
필요**하다. `Field.serverID`가 있어 `venueId`는 바로 넘길 수 있다.

## 범위와 수정 경로

**편집 가능 조건**: 로컬 기록이 있는 경기만. `OwnMatchAnalysisLoader`로 서버에서
복원된 엔트리는 `records`가 비고 `sourceRecord`가 nil이라 로컬 `field`를 쓸 대상이
없다 → `entry.records.isEmpty`이면 변경 행을 숨긴다.

**진실의 원천**: `WorkoutRecord.field`(SwiftData). 쿼터별로 이미 독립 필드이므로
모델 변경은 없다.

**기본 단위는 경기 전체 일괄 변경**이고, 쿼터별 변경도 제공한다.

### 공통 컴포넌트

- `FieldAssignmentModel` (`@MainActor @Observable`): `fieldsByQuarterID: [UUID: Field]`
  상태와 `apply(_ field: Field, to scope: Scope)` (`.allQuarters` / `.quarter(UUID)`).
  저장 실패 시 이전 값으로 롤백한다. 지금 `ReadyForDetailView.assignMissingFields`의
  롤백 로직을 여기로 옮기고 `fieldsByQuarterID` 중복 상태를 없앤다.
- `FieldChangeRow`: "운동장 · 〈이름〉" + 변경 버튼. 미지정이면 "운동장 지정하기".
- 적용 범위 선택: 쿼터가 2개 이상이고 경기 단위 진입점에서 들어왔을 때만
  `confirmationDialog`로 "모든 쿼터에 적용 / 이 쿼터만"을 묻는다. 쿼터가 1개면 생략한다.
- 운동장 선택은 기존 `FieldListView(onFieldSelected:)`를 재사용한다(신규 등록 경로 포함).

### 화면별 배치

- **ReadyForDetailView**: `directionGuide` 아래에 경기 단위 `FieldChangeRow`, 각
  `CardQuarterView` 히트맵 위에 쿼터 단위 `FieldChangeRow`. 기존
  `fieldAssignmentNotice`(미지정 경고)와 `hasMissingFields` 게이트는 유지한다.
- **AnalysisDetailView**: `positionRow` 아래에 `FieldChangeRow`. `AnalysisQuarter`가
  값 타입이라 `FieldAssignmentModel`의 오버레이를 `TrackingMapPager(field:)`에
  주입해 히트맵이 즉시 다시 그려지게 한다.

## 서버 동기화 (B 시도 → A 폴백)

**아직 제출되지 않은 경기**(`submissionIdempotencyKey == nil`): 서버 호출 없음.
바뀐 운동장이 첫 제출에 그대로 실려 간다(ReadyForDetail의 기존 동작).

**이미 제출된 경기**의 수정 순서:

1. `VenueStore.ensureUploaded(field)`로 새 운동장의 `serverID`를 확보한다.
2. `MatchEndpoints.detail(matchId:)`로 최신 `version`을 조회한다. 404면 서버에 없는
   경기이므로 로컬 수정만 하고 끝낸다(에러로 취급하지 않는다).
3. **B: 재전송 시도** — `submissionIdempotencyKey`를 새 UUID로 교체하고, 2에서 받은
   version을 `If-Match`로 넣어 `workout-submissions`를 다시 POST한다. 바뀐
   `workout.field`가 쿼터별로 반영된다.
4. **B 실패 시 A로 폴백** — `MatchEndpoints.update(matchId:, venueId: field.serverID,
   venueSnapshot: VenueSnapshot(name:address:), ifMatch:)`. 경기 대표 운동장만
   갱신되고 쿼터 `workout.field`는 옛 값으로 남는다.
5. **둘 다 실패**: 로컬 수정은 유지하고 "서버에 반영하지 못했어요 · 다시 시도"를
   안내한다. `submissionIdempotencyKey`는 실패 전 값으로 롤백해 원래 제출 상태를
   깨지 않는다.

## 리팩터링

`ReadyForDetailView`에 인라인으로 있는 `submitWorkouts` / `ensureFieldsAreUploaded` /
`workoutFieldPayload` / `repairDuplicateQuarterIDs`를 `Respository/WorkoutSubmissionStore`로
옮긴다. Detail에서 재전송하려면 재사용이 필요하고, 404줄짜리 뷰에서 네트워킹이
빠지면 양쪽 화면이 같은 제출 경로를 쓰게 된다.

## 재전송 가능성 검증

- dev 계정에서 새 `Idempotency-Key` + 최신 `If-Match`로 2회 제출했을 때 서버가
  **갱신**하는지, **409/중복 쿼터 생성**인지 확인하고 응답을 로깅한다.
- 쿼터가 중복 생성되는 동작이면 B는 버리고 A만 남긴다(결과는 이슈 #96에 기록).
  판단이 나기 전까지 B 경로는 폴백을 포함한 상태로 둔다.

## 테스트

- `FieldAssignmentModel`: 일괄 적용, 단일 쿼터 적용, 저장 실패 시 롤백.
- 서버 동기화: 미제출 경기(호출 없음), 404(로컬만), B 성공, B 실패 후 A 성공,
  둘 다 실패(로컬 유지 + 키 롤백)를 가짜 Provider로 검증한다.
