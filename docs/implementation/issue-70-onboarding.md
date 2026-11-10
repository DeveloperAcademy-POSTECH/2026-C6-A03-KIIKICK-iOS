# #70 온보딩 완료 API

- 이슈: https://github.com/DeveloperAcademy-POSTECH/2026-C6-A03-KIIKICK-iOS/issues/70
- 계약: https://kiikick-api.duckdns.org/swagger-ui/index.html#/Auth%20/%20%EC%98%A8%EB%B3%B4%EB%94%A9/completeOnboarding
- 2026-11-10 배포 `/v3/api-docs`의 `OnboardingRequest`, `UserSelfSuccess` 확인.

가입 완료 버튼에서 계정 생성 → 선택 사진 업로드 → 프로필 상태 조회 → `PUT /api/v1/users/me/onboarding`을 수행한다. 닉네임 PATCH는 더 이상 가입 완료에 사용하지 않는다. 서버가 완료를 확인한 뒤 기존 환영 화면을 3초 표시하고 홈 탭으로 이동한다. 화면이 사라지면 대기와 요청 작업을 취소한다.

본문은 `nickname`과 `consents: []`이다. 현재 온보딩에는 동의 선택 UI가 없으며, Swagger는 빈 배열을 허용한다. 위치·건강 데이터 OS 권한을 서버 동의로 추정해 전송하지 않는다. Bearer 토큰과 UUID `Idempotency-Key`를 포함하며, 동일 화면의 재시도는 같은 키·닉네임을 유지한다. 공통 JSON 인코더는 키를 정렬해 재시도 본문 바이트도 동일하게 만든다(전송 필드와 값은 동일).

사진은 기존 `AvatarImage`(방향 보정·1024px JPEG·5 MiB 제한)와 `AvatarEndpoints` multipart 업로드를 재사용한다. 선택하지 않으면 업로드 요청을 보내지 않는다. 업로드 실패 시 완료하지 않고 오류를 보여준다. 업로드 성공 후 온보딩만 실패하면 사진은 재전송하지 않는다.

계정 생성 성공 후 재시도는 signup을 반복하지 않는다. 완료 응답이 유실되거나 앱을 다시 열었을 때 프로필 조회가 이미 `COMPLETED`이면 PUT을 반복하지 않는다. 로그인·토큰 갱신·프로필 응답에서 온보딩 상태를 저장해 `REQUIRED` 계정은 닉네임/사진 화면으로 다시 진입한다. 가입 후에는 소비된 가입 토큰으로 이전 단계를 다시 제출하지 않도록 이전 버튼을 비활성화한다.

## 검증

- `scripts/validation/check-onboarding.sh`: 실제 Endpoint/DTO/완료 모델/라우터를 사용하고 저장소·네트워크는 대체한다. PUT 본문·헤더, 선택 사진, 부분 실패 재시도, 동일 멱등 키, 응답 유실, 미완료 계정 재진입, 중복 제출, 취소, 홈 탭 초기화를 검증한다.
- iOS/watchOS Simulator Debug·Release 빌드 확인.
- 실서버 사용자 생성·사진 업로드는 수행하지 않았다. 실제 계정으로 UI 전체 흐름을 검증하는 것은 별도 확인이 필요하다.

## Design Gaps — 가입 완료

- 🟡 API 오류·진행 상태의 별도 디자인은 미확인. 기존 사진 설정/환영 화면(Figma 575:9884 / 575:9916), 기존 오류 영역과 CTA 비활성 상태를 재사용한다. 새 색상·레이아웃 토큰은 추가하지 않았다.

## 디버그 콘솔

Debug 빌드에서는 표준 출력(print)으로 요청 시작·결과를 남긴다. `[API]`로 필터하면 요청별 메서드·경로·HTTP 상태를 확인할 수 있다. 실패 응답은 `error.code`와 `meta.requestId`를 추가 표시한다. 전송 실패는 NSError 도메인·코드를 표시한다. 성공한 사진 업로드(POST /users/me/avatar)와 가입 실패(POST /auth/signup)를 구분할 수 있다. 이 추가 로깅은 Release에 포함하지 않으며 토큰·본문·사진·쿼리 문자열을 출력하지 않는다.
