# 경기장 API 동기화

## API 연결

- 목록: `GET /api/v1/venues`를 전 페이지 조회해 서버 UUID 기준으로 로컬 `Field`를 갱신한다.
- 등록: `POST /api/v1/venues`가 성공한 뒤 응답 UUID와 좌표를 SwiftData에 저장한다.
- 수정: 경기 준비 화면에서 기존 핀과 이름을 편집하고, 보정 좌표·원본 좌표 전체를 `PATCH /api/v1/venues/{venueId}`로 보낸 뒤 로컬에 반영한다.
- 삭제: `DELETE /api/v1/venues/{venueId}` 성공 후 로컬 경기장을 보관 처리한다. 서버의 404는 이미 삭제된 상태로 간주한다.

모든 쓰기 요청은 UUID 형식의 `Idempotency-Key`를 보낸다. 같은 내용의 실패 재시도에는 같은 키를 사용하고, 사용자가 이름을 바꾸면 새 키를 발급한다.

## 기존 로컬 데이터

API 연동 전에 생성되어 `serverID`가 없는 경기장은 목록 동기화 시 서버로 한 번 이전한다. 전송 전에 멱등 키를 SwiftData에 저장하므로 응답 유실이나 일시적인 실패 뒤에도 같은 요청을 재생한다.

## 삭제 정책

`WorkoutRecord.field`가 과거 분석 화면의 좌표 스냅샷 역할을 하므로 SwiftData 객체를 직접 삭제하지 않는다. `isArchived`로 내 경기장 목록에서만 숨겨 기존 경기의 히트맵·스프린트 좌표를 보존한다.
