# #75 친구 경기 조회·댓글 테스트 목록

- 대상 브랜치: `feat/#75-friend-match-results`
- 구현 문서: [issue-75-friend-matches-comments.md](issue-75-friend-matches-comments.md)
- 분류: **[A]** 이미 자동 검증됨 / **[B]** 자동 검증에 추가 필요 / **[C]** 시뮬레이터 수동 / **[D]** 실계정 통합

---

## A. 이미 자동 검증된 항목

`scripts/validation/check-friend-matches.sh` (= `Tests/FriendMatchChecks.swift`)가 실제 Provider·Endpoint·DTO에 가짜 `URLSession`을 주입해 확인한다. **현재 PASS.**

- [x] 목록·결과·쿼터 응답 디코딩, `Authorization: Bearer` 헤더, `status=COMPLETED` 쿼리
- [x] 친구 데이터를 로컬 `WorkoutRecord`로 저장하지 않음 (`entry.records.isEmpty`)
- [x] 미제출 경기(`workout == nil`)는 제외하고 다음 페이지까지 읽어 공개 경기를 찾음
- [x] 쿼터 페이지 커서 추가 조회, m/s → km/h 변환(28.8), 섹션 2개 구성
- [x] `calculationStatus = PROCESSING` 쿼터는 지표 `—`, 섹션 비움
- [x] 목록 403 → 기존 경기 제거 + 에러 메시지
- [x] 댓글 중복 ID 제거, 작성자 프로필 중복 조회 안 함
- [x] 1001자 입력 차단(`canSend == false`, 안내 문구)
- [x] 전송 실패 시 입력 유지 → 재시도 시 동일 body·동일 `Idempotency-Key`
- [x] `DELETE` 엔드포인트 계약(메서드/빈 body)

---

## B. 자동 검증에 추가할 항목

스크립트로 바로 검증 가능한 분기인데 현재 빠져 있다. 우선순위 순.

### B-1. 공개 조건 (`FriendMatchAnalysis.init?`)

가드 절이 7개인데 `workout == nil`만 검증돼 있다. 나머지가 뚫리면 **비공개 경기가 친구에게 노출**된다.

- [ ] `quarterCount == 0` → `nil`
- [ ] `quarters.count != result.quarterCount` (쿼터 일부만 도착) → `nil`
- [ ] 쿼터 ID 중복 → `nil`
- [ ] `quarter.matchId`가 경기 ID와 불일치 → `nil`
- [ ] `quarter.status != .completed` → `nil`
- [ ] `position == nil` → `nil`

### B-2. 지표 fallback

- [ ] `stats`가 없으면 `workout.events`로 골/어시스트 집계
- [ ] `stats`도 `events`도 없으면 `nil` → 화면에 `—` (0을 만들지 않음)
- [ ] `calculationStatus = FAILED` → 지표 `—` (현재 `PROCESSING`만 검증됨)
- [ ] 심박 값이 모두 없으면 `Physical Activity` 섹션 생략
- [ ] `trimpEdwards`가 없으면 `Training Load` 섹션 생략
- [ ] `fieldName` fallback: `workout.field.name` → `venueSnapshot.name` → `"운동장 미지정"`
- [ ] 날짜 fallback: `startedAt` → `scheduledAt` → `createdAt`
- [ ] `durationText` 포맷 — 초가 2자리로 패딩되는지 (`9:05`)

### B-3. 목록 모델 (`FriendMatchListModel`)

- [x] 개별 경기 조회가 404/409면 그 경기만 건너뛰고 나머지는 노출
- [x] `hasNext == true`인데 `nextCursor == nil` → `NetworkError.components` (무한 루프 방지)
- [ ] 같은 커서가 다시 오면 중단 (`seenCursors`)
- [ ] 목록에 `ownerId != userID` 항목이 섞이면 제외
- [ ] 중복 경기 ID 제거
- [ ] 날짜 내림차순 정렬
- [ ] 목록 404 → 기존 경기 제거 (현재 403만 검증됨)

### B-4. 쿼터 로더 (`FriendMatchLoader`)

- [ ] `result.match.id`가 요청한 `matchID`와 다르면 `decodeError`
- [ ] `result.match.ownerId`가 요청한 `userID`와 다르면 `decodeError`
- [ ] 쿼터 페이지 커서가 반복되면 `NetworkError.components`

### B-5. 댓글 모델 (`MatchCommentsModel`)

- [ ] `matchID == nil` → `canSend == false`, 네트워크 요청 0건
- [ ] 공백·개행만 입력 → `canSend == false`
- [ ] 정확히 1000자 → 전송 **가능** (경계값)
- [ ] 작성 응답의 `matchId`가 다르면 `decodeError`, 목록에 추가 안 함
- [ ] 작성자 프로필 조회 실패 → 닉네임 `"사용자"` + 기본 이미지
- [ ] 프로필 응답 `id`가 요청 id와 다르면 캐시하지 않음
- [ ] 댓글 403/404 → 목록·작성자·커서 초기화 (`clearOnAccessLoss`)
- [ ] 2페이지 추가 조회 시 중복 제거하며 누적
- [ ] `hasNext == true`인데 `nextCursor`가 현재 커서와 같으면 `components`
- [ ] `createdAt` 내림차순 정렬
- [ ] 입력 내용을 바꿔 재전송하면 **새** `Idempotency-Key` 발급
- [ ] 전송 중 사용자가 입력을 바꿨으면 성공 후에도 입력을 비우지 않음 (`MatchCommentsModel.swift:80`)

---

## C. 시뮬레이터 수동 QA

### C-1. 친구 프로필 (`UserProfileView`)

- [ ] 친구 상태에서 진입 → 경기 카드 목록과 월 선택기 표시
- [ ] 친구 아님/요청중/차단 상태 → 경기 목록 영역 자체가 안 보임 (`matches.clear()`)
- [ ] 공개 경기가 0건 → `"공개된 경기 기록이 없어요"` 빈 상태
- [ ] 조회 실패 → 빨간 안내 문구 + `"다시 시도"` 버튼, 탭하면 재조회
- [ ] `hasNext` → `"경기 더 보기"` 버튼 노출, 탭하면 다음 페이지 누적
- [ ] 로딩 중 `ProgressView`, 버튼 비활성
- [ ] 선택한 월에 기록이 없으면 기록이 있는 최신 월로 자동 이동 (`syncMonth`)
- [ ] 월을 바꾸면 해당 월 경기만 필터링
- [ ] 아래로 당겨 새로고침(`refreshable`) 동작
- [ ] 카드 탭 → `FriendMatchDetailView` 푸시, 탭바 숨김

### C-2. 친구 경기 상세 (`FriendMatchDetailView` + `AnalysisDetailView`)

- [ ] 네비게이션 타이틀이 `"닉네임 · 날짜"`
- [ ] 로딩 중 `ProgressView`
- [ ] 조회 실패 → `"경기를 불러올 수 없어요…"` + `"다시 불러오기"` 버튼
- [ ] **숨겨져야 하는 것**: 공유 버튼, `"삭제하기"` CTA, `"함께 뛴 친구 N명"`, `"히트맵과 포지션이 정확한지 확인해주세요"`, `"타임라인 보기"`
- [ ] 맵 영역에 경기장 그림 + `"친구의 위치 경로는 제공되지 않아요"` 안내
- [ ] 쿼터 선택을 바꾸면 Key Stats·섹션·골/어시스트가 그 쿼터 값으로 바뀜
- [ ] 계산 중/미제공 지표가 `0`이 아니라 `—`로 표시
- [ ] 단위가 km/h, km로 표시 (서버 m/s, m 아님)

### C-3. 댓글 시트 (`MatchCommentsSheet`)

- [ ] 접힌 상태(`.height(70)`)에서는 `"댓글 N"` 헤더만, 입력창 숨김
- [ ] `.large`로 끌어올리면 입력창 노출
- [ ] `hasNext`일 때 헤더가 `"댓글 N+"`
- [ ] 답글 버튼이 **보이지 않음** (대댓글 API 없음)
- [ ] 1000자 초과 입력 → 빨간 안내 + 전송 버튼 비활성
- [ ] 공백만 입력 → 전송 버튼 비활성
- [ ] 전송 성공 → 목록 맨 위에 추가되고 입력창 비워짐
- [ ] 전송 실패 → 입력 유지 + 에러 문구, 재시도로 성공
- [ ] 전송 중 중복 탭 → 요청 1건만 (`isSending`)
- [ ] 작성자 닉네임·프로필 사진 표시, 조회 실패 시 `"사용자"` + 기본 이미지
- [ ] 목록 바깥 탭 / 스크롤로 키보드 내려감
- [ ] `"댓글 더 보기"` 탭 → 다음 페이지 누적

### C-4. 내 경기 회귀 (중요 — 공용 뷰를 건드렸다)

`AnalysisDetailView`는 내 경기에서도 쓰는 뷰다. `isOwner` 분기가 기존 동작을 깨지 않았는지 확인한다.

- [ ] 내 경기 상세에서 공유 버튼, `"삭제하기"`, `"함께 뛴 친구"`, `"타임라인 보기"`가 **그대로** 보임
- [ ] 내 경기 히트맵/스프린트 페이저가 정상 동작 (`TrackingMapPager`)
- [ ] 내 경기 Key Stats가 쿼터 전환에 따라 기존과 동일하게 표시
- [ ] 내 경기 댓글 시트가 서버 댓글을 불러옴 (`entry.records.first?.matchId`)
- [ ] 서버 `matchId`가 없는 경기/Preview → 네트워크 요청 없이 빈 목록, 전송 비활성
- [ ] 시트 기본 높이가 `70`으로 바뀐 게 어색하지 않은지 (기존 `140`)

---

## D. 실계정 통합 테스트

아직 실행하지 않았다. 계정 2개(A·B)가 필요하다.

- [ ] A·B 친구 수락 → B 프로필에서 B의 완료 경기가 보임
- [ ] B가 아직 분석 보기를 안 한 경기는 A에게 **안 보임**
- [ ] B가 분석 보기를 완료한 뒤 A가 새로고침 → 경기 등장
- [ ] A가 B 경기에 댓글 작성 → B 계정에서 같은 댓글 확인
- [ ] B가 댓글 작성 → A 화면에서 작성자 닉네임·사진이 B로 표시
- [ ] 친구 삭제 후 A가 B 프로필 재진입 → 경기 목록 사라짐
- [ ] 이미 보던 친구 경기 상세에서 친구 관계가 끊긴 뒤 새로고침 → 403/404 처리로 데이터 제거
- [ ] 토큰 만료 상태에서 진입 → `refreshToken` 재인증(#63) 후 정상 조회
- [ ] 기내 모드 → 에러 문구 + 재시도 버튼, 크래시 없음
- [ ] 쿼터 10개 이상/댓글 50개 이상 경기에서 페이지네이션과 스크롤 성능

---

## E. 빌드·기존 검증

- [x] iOS Simulator Debug 빌드 (`xcodebuild -scheme KIIKICK`) — **BUILD SUCCEEDED**
- [ ] iOS Simulator Release 빌드
- [ ] watchOS Simulator Debug·Release 빌드 (공용 모델을 건드렸으므로 확인)
- [ ] `scripts/validation/` 기존 스크립트 전체 (온보딩·OVR·지도)
- [ ] 실기기 1회 실행

---

## 알려진 비범위 (테스트 대상 아님)

구현 문서에 적힌 의도적 제외다. 버그로 올리지 않는다.

- 친구 히트맵·스프린트·타임라인 — 서버에 친구 경로 조회 API가 없다
- 대댓글 — 서버 계약이 단층 댓글만 제공한다
- 댓글 삭제 버튼 — 엔드포인트만 정의하고 UI 미연결
- `분석 보기` 공개 여부를 운동 데이터 제출 상태로 대체 판정 — 서버에 공개 상태 필드가 없다
