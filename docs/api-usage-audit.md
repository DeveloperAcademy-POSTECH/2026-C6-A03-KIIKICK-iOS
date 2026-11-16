# KIIKICK iOS API 사용 현황

- 확인일: 2026-11-15
- 배포 Swagger: <https://kiikick-api.duckdns.org/swagger-ui/index.html#/>
- OpenAPI JSON: <https://kiikick-api.duckdns.org/v3/api-docs>
- 명세 버전: OpenAPI 3.1.0 / KIIKICK Backend API v1
- 전체 규모: 63 paths, 81 operations

## 판정 기준

- **사용 중**: `NetworkTestView`, 테스트 코드, 주석을 제외한 제품 화면·Model·Repository에서 실제 `Provider` 요청을 호출한다.
- **테스트·개발 도구 전용**: iOS Endpoint 구현은 있으나 `NetworkTestView` 또는 검증 테스트에서만 호출한다.
- **구현만 존재**: iOS Endpoint 구현은 있으나 제품과 테스트 어디에서도 호출하지 않는다.
- **iOS 미구현**: 배포 Swagger에는 있으나 대응하는 iOS Endpoint가 없다.

Endpoint 선언만으로는 사용 중으로 보지 않았다. 실제 호출부는 `KIIKICK/KIIKICK/Features`, `Core`, `Respository`를 기준으로 확인했다.

## 요약

| 구분 | 개수 |
| --- | ---: |
| 제품에서 사용 중 | 41 |
| 테스트·개발 도구 전용 | 31 |
| iOS 구현만 있고 호출 없음 | 4 |
| Swagger에는 있으나 iOS 미구현 | 5 |
| 합계 | 81 |

## 제품에서 사용 중인 API

### 인증·프로필

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| POST | `/api/v1/auth/email-verifications` | 회원가입 이메일 인증번호 발송 |
| POST | `/api/v1/auth/email-verifications/{verificationId}/verify` | 인증번호 검증 및 registration token 발급 |
| POST | `/api/v1/auth/signup` | 이메일 회원가입 및 세션 생성 |
| POST | `/api/v1/auth/login` | 로그인 |
| POST | `/api/v1/auth/refresh` | Access Token 갱신 |
| GET | `/api/v1/users/me` | 현재 사용자 프로필 조회 |
| PATCH | `/api/v1/users/me` | 닉네임 등 프로필 수정 |
| PUT | `/api/v1/users/me/onboarding` | 온보딩 완료 |
| POST | `/api/v1/users/me/avatar` | 프로필 이미지 등록·교체 |

### 사용자·운동 원본

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| DELETE | `/api/v1/user/{userId}` | 계정 삭제 |
| POST | `/api/v1/user/{userId}/workout-payloads` | 기존 사용자 단위 WorkoutPayload 업로드 |

### 친구

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/users/search` | 친구 추가 화면 사용자 검색 |
| GET | `/api/v1/users/{userId}/profile` | 사용자·댓글 작성자 공개 프로필 조회 |
| GET | `/api/v1/friends` | 친구 목록 조회 |
| GET | `/api/v1/friend-requests` | 받은 친구 요청 조회 |
| POST | `/api/v1/friend-requests` | 친구 요청 전송 |
| POST | `/api/v1/friend-requests/{requestId}/accept` | 친구 요청 수락 |
| DELETE | `/api/v1/friend-requests/{requestId}` | 친구 요청 거절·취소 |
| DELETE | `/api/v1/friends/{userId}` | 친구 삭제 |

### 친구 경기 분석

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/friends/{userId}/matches` | 친구의 완료 경기 목록 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/venue` | 친구 경기장 정보 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/result` | 친구 경기 결과 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/result/quarters` | 친구 경기 쿼터 결과 목록 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/quarters/{quarterId}/heatmap` | 친구 쿼터 히트맵 |

### 댓글

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/matches/{matchId}/comments` | 본인·친구 경기 댓글 목록 |
| POST | `/api/v1/matches/{matchId}/comments` | 경기 댓글 작성 |

### 내 경기·결과·운동 제출

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/matches` | 완료 경기 목록과 홈 최근 기록 동기화 |
| GET | `/api/v1/matches/{matchId}` | 운동 일괄 제출 전 최신 경기 version 조회 |
| GET | `/api/v1/matches/{matchId}/result` | 완료 경기 결과 조회 |
| GET | `/api/v1/matches/{matchId}/result/quarters` | 완료 경기 쿼터 결과 목록 |
| POST | `/api/v1/matches/{matchId}/workout-submissions` | 운동 기록·포지션 일괄 제출 |
| GET | `/api/v1/quarters/{quarterId}/track-points` | 내 경기 GPS 원본 경로 조회 |

### 알림

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/notifications` | 알림 목록 |
| PUT | `/api/v1/notifications/{notificationId}/read` | 알림 읽음 처리 |

### 쿼터 참여 친구

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/matches/{matchId}/quarters/{quarterId}/friends` | 함께 뛴 친구 조회 |
| PUT | `/api/v1/matches/{matchId}/quarters/{quarterId}/friends/{friendUserId}` | 함께 뛴 친구 추가 |
| DELETE | `/api/v1/matches/{matchId}/quarters/{quarterId}/friends/{friendUserId}` | 함께 뛴 친구 제거 |

### 경기장

| Method | Path | 사용 위치/목적 |
| --- | --- | --- |
| GET | `/api/v1/venues` | 저장 경기장 목록 동기화 |
| POST | `/api/v1/venues` | 경기장 저장 |
| PATCH | `/api/v1/venues/{venueId}` | 경기장 수정 |
| DELETE | `/api/v1/venues/{venueId}` | 경기장 삭제 |

## 현재 제품에서 사용하지 않는 API

### iOS 구현은 있으나 테스트·개발 도구에서만 사용

| Method | Path | 비고 |
| --- | --- | --- |
| POST | `/api/v1/auth/logout` | 실제 로그아웃 화면에서는 서버 요청을 호출하지 않음 |
| GET | `/api/v1/analytics/summary` | `NetworkTestView` 전용 |
| GET | `/api/v1/analytics/trends` | `NetworkTestView` 전용 |
| GET | `/api/v1/analytics/match-comparison` | `NetworkTestView` 전용 |
| GET | `/api/v1/analytics/positions` | `NetworkTestView` 전용 |
| GET | `/api/v1/analytics/friend-comparison` | `NetworkTestView` 전용 |
| PUT | `/api/v1/users/{userId}/block` | 차단 UI 없음 |
| DELETE | `/api/v1/users/{userId}/block` | 차단 해제 UI 없음 |
| DELETE | `/api/v1/matches/{matchId}/comments/{commentId}` | Endpoint와 검증 테스트만 있고 삭제 UI 미연결 |
| GET | `/api/v1/matches/{matchId}/quarters/{quarterId}/stats` | `NetworkTestView` 전용 |
| PUT | `/api/v1/matches/{matchId}/quarters/{quarterId}/stats` | `NetworkTestView` 전용 |
| GET | `/api/v1/matches/{matchId}/quarters/{quarterId}/position` | `NetworkTestView` 전용 |
| PUT | `/api/v1/matches/{matchId}/quarters/{quarterId}/position` | `NetworkTestView` 전용 |
| POST | `/api/v1/matches` | 경기 생성 플로우와 미연결 |
| POST | `/api/v1/matches/{matchId}/{action}` | ready/cancel/start/end Endpoint는 있으나 제품 플로우와 미연결 |
| GET | `/api/v1/matches/{matchId}/quarters` | `NetworkTestView` 전용 |
| POST | `/api/v1/matches/{matchId}/quarters` | `NetworkTestView` 전용 |
| POST | `/api/v1/matches/{matchId}/quarters/{quarterId}/{action}` | start/end/complete Endpoint는 있으나 제품 플로우와 미연결 |
| PATCH | `/api/v1/matches/{matchId}` | `NetworkTestView` 전용 |
| DELETE | `/api/v1/matches/{matchId}/quarters/{quarterId}` | `NetworkTestView` 전용 |
| PATCH | `/api/v1/matches/{matchId}/quarters/{quarterId}` | `NetworkTestView` 전용 |
| GET | `/api/v1/quarters/{quarterId}/result` | `NetworkTestView` 전용 |
| GET | `/api/v1/notifications/unread-count` | `NetworkTestView` 전용 |
| PUT | `/api/v1/devices/{deviceId}` | 기기·푸시 등록 플로우와 미연결 |
| DELETE | `/api/v1/devices/{deviceId}` | 기기 등록 해제 플로우와 미연결 |
| POST | `/api/v1/quarters/{quarterId}/workout-payloads` | `NetworkTestView` 전용 |
| GET | `/api/v1/quarters/{quarterId}/workout` | `NetworkTestView` 전용 |
| GET | `/api/v1/quarters/{quarterId}/summary` | `NetworkTestView` 전용 |
| GET | `/api/v1/quarters/{quarterId}/heart-rate-samples` | `NetworkTestView` 전용 |
| PUT | `/api/v1/quarters/{quarterId}/summary/settings` | `NetworkTestView` 전용 |
| POST | `/api/v1/quarters/{quarterId}/summary/recalculate` | 쿼터 요약 재계산이며, 경기 전체 재분석 API는 아님 |

### iOS Endpoint 구현만 있고 호출 없음

| Method | Path | iOS Endpoint |
| --- | --- | --- |
| POST | `/api/v1/user` | `UserEndpoints.create` |
| GET | `/api/v1/user/{userId}` | `UserEndpoints.get` |
| PUT | `/api/v1/user/{userId}` | `UserEndpoints.update` |
| GET | `/api/v1/venues/{venueId}` | `VenueEndpoints.detail` |

### Swagger에는 있으나 iOS 미구현

| Method | Path | 비고 |
| --- | --- | --- |
| GET | `/api/v1/users` | 전체 사용자 조회 |
| DELETE | `/api/v1/users/me/avatar` | 내 프로필 사진 제거 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}` | 친구 경기 상세 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/quarters` | 친구 경기 쿼터 목록 |
| GET | `/api/v1/friends/{userId}/matches/{matchId}/quarters/{quarterId}/result` | 친구 쿼터 상세 결과 |

## 확인된 계약상 주의점

- Swagger의 댓글 작성 응답 표기와 실제 서버 응답이 다르다. 앱은 현재 `201 { data: CommentResponse, meta }` 형태로 디코딩한다.
- `POST /api/v1/quarters/{quarterId}/summary/recalculate`는 한 쿼터의 요약 지표 재계산이다. 완료 경기 전체 분석을 다시 수행하는 API는 현재 Swagger에 없다.
- 친구 경기의 원본 GPS는 공개되지 않는다. 앱은 친구 히트맵 전용 집계 API만 사용한다.
- 일부 경기·쿼터 변경 API는 `If-Match`가 필요하지만 Provider가 응답 ETag를 노출하지 않아 실제 제품 플로우에 연결되지 않았다.
- 인증 공개 API를 제외하면 Bearer Access Token이 필요하다는 것이 Swagger 설명의 기본 계약이다.

## 추가 요청 API

아래 두 기능은 2026-11-15 기준 배포 Swagger에 없다. 백엔드 구현과 Swagger 계약 추가를 요청한다.

### 1. 댓글에 답글 달기 API 구현 요청

경기 댓글에 단층 댓글만 제공되고 있어 Figma의 답글 기능을 구현할 수 없다. 다음 계약 또는 동등한 형태의 대댓글 작성 API가 필요하다.

- 제안: `POST /api/v1/matches/{matchId}/comments/{commentId}/replies`
- 인증: Bearer Access Token
- 헤더: `Idempotency-Key` 지원
- 요청 예시:

```json
{
  "content": "답글 내용"
}
```

- 응답에는 답글 ID, 경기 ID, 부모 댓글 ID, 작성자 ID, 내용, 작성 시각이 필요하다.
- 댓글 목록 응답에도 답글 목록 또는 `parentCommentId`와 페이지네이션 계약이 필요하다.
- 원댓글과 동일한 경기 조회 권한, 삭제·차단 사용자 정책을 적용해야 한다.

### 2. 경기 재분석 요청 API 구현 요청

완료 경기의 운동 원본·포지션·스탯이 수정되거나 분석 처리에 실패했을 때 경기 전체 분석을 다시 요청할 API가 필요하다. 기존 쿼터 summary 재계산 API와는 별도 기능이다.

- 제안: `POST /api/v1/matches/{matchId}/analysis/recalculate`
- 인증: Bearer Access Token 및 경기 소유권 확인
- 헤더: `Idempotency-Key`, 필요 시 `If-Match`
- 권장 응답: 비동기 작업이면 `202 Accepted`
- 응답 예시:

```json
{
  "data": {
    "analysisJobId": "UUID",
    "matchId": "UUID",
    "status": "QUEUED"
  }
}
```

- 중복 요청 처리, 진행 상태(`QUEUED`, `PROCESSING`, `COMPLETED`, `FAILED`) 조회 방법, 완료 알림 계약이 필요하다.
- 재분석 완료 후 경기·쿼터 결과, 히트맵, 추세 지표가 일관되게 갱신되어야 한다.

## 주요 대조 파일

- [`Respository/Network/API`](../KIIKICK/KIIKICK/Respository/Network/API)
- [`NetworkTestView.swift`](../KIIKICK/KIIKICK/Features/View/Auth/NetworkTestView.swift)
- [`OwnMatchAnalysisLoader.swift`](../KIIKICK/KIIKICK/Respository/OwnMatchAnalysisLoader.swift)
- [`FriendMatchLoader.swift`](../KIIKICK/KIIKICK/Respository/FriendMatchLoader.swift)
- [`MatchCommentsModel.swift`](../KIIKICK/KIIKICK/Features/View/Analysis/MatchCommentsModel.swift)
- [`QuarterFriendsModel.swift`](../KIIKICK/KIIKICK/Features/View/Analysis/QuarterFriendsModel.swift)
