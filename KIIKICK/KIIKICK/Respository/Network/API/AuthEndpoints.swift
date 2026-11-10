//
//  AuthEndpoints.swift
//  KIIKICK
//
//  실제 배포된 Swagger(/v3/api-docs) 기준 — 이메일 인증 → 회원가입/로그인 흐름.
//  docs/api/auth.md(AUTH-01~10)는 OAuth 제공자 토큰 교환 설계라 실제 구현과 다르다
//  (AuthDTO.swift 상단 주석 참고). multipart 사진 업로드는 AvatarEndpoints에서 처리한다.
//
//  가입 흐름: requestEmailVerification(email) → (사용자가 메일로 받은 코드 입력) →
//  verifyEmailVerification(verificationId, code)로 registrationToken 발급 →
//  signup(registrationToken, password)로 계정 생성 + 즉시 로그인된 세션 반환.
//

import Foundation

enum AuthEndpoints {
    /// registrationToken + 비밀번호로 계정을 만들고, 만든 즉시 로그인된 세션을 받는다.
    static func signup(registrationToken: String, password: String) -> Endpoint<Envelope<SessionResponse>> {
        Endpoint(
            path: "/api/v1/auth/signup",
            method: .post,
            bodyParameters: SignupRequest(registrationToken: registrationToken, password: password)
        )
    }

    /// 같은 요청을 재시도할 때는 동일한 키와 본문을 유지한다.
    static func completeOnboarding(nickname: String, idempotencyKey: UUID) -> Endpoint<Envelope<AuthUserResponse>> {
        Endpoint(
            path: "/api/v1/users/me/onboarding",
            method: .put,
            bodyParameters: OnboardingRequest(nickname: nickname),
            headers: bearerHeaders().merging(["Idempotency-Key": idempotencyKey.uuidString]) { $1 }
        )
    }

    /// access token 만료 시 refresh token으로 새 세션을 발급받는다.
    static func refresh(refreshToken: String) -> Endpoint<Envelope<SessionResponse>> {
        Endpoint(
            path: "/api/v1/auth/refresh",
            method: .post,
            bodyParameters: RefreshRequest(refreshToken: refreshToken)
        )
    }

    static func login(email: String, password: String) -> Endpoint<Envelope<SessionResponse>> {
        Endpoint(
            path: "/api/v1/auth/login",
            method: .post,
            bodyParameters: LoginRequest(email: email, password: password)
        )
    }

    /// sessionId를 생략하면 현재 access token의 세션을 로그아웃한다.
    static func logout(sessionId: UUID? = nil) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/auth/logout",
            method: .post,
            bodyParameters: LogoutRequest(sessionId: sessionId),
            headers: bearerHeaders().merging(idempotencyHeaders()) { $1 }
        )
    }

    /// 내 프로필 조회.
    static func profile() -> Endpoint<Envelope<AuthUserResponse>> {
        Endpoint(path: "/api/v1/users/me", method: .get, headers: bearerHeaders())
    }

    /// 닉네임/아바타 URL 수정 — 최소 1개 필드가 필요하다.
    static func updateProfile(nickname: String? = nil, avatarUrl: String? = nil) -> Endpoint<Envelope<AuthUserResponse>> {
        Endpoint(
            path: "/api/v1/users/me",
            method: .patch,
            bodyParameters: ProfilePatchRequest(nickname: nickname, avatarUrl: avatarUrl),
            headers: bearerHeaders().merging(idempotencyHeaders()) { $1 }
        )
    }
    
    /// 이메일로 인증 코드 발송.
    static func requestEmailVerification(email: String) -> Endpoint<Envelope<EmailVerificationResponse>> {
        Endpoint(
            path: "/api/v1/auth/email-verifications",
            method: .post,
            bodyParameters: EmailVerificationRequest(email: email)
        )
    }

    /// 인증 코드 확인 — 성공하면 회원가입에 쓸 registrationToken을 돌려준다.
    static func verifyEmailVerification(verificationId: UUID, code: String) -> Endpoint<Envelope<EmailVerificationSuccessResponse>> {
        Endpoint(
            path: "/api/v1/auth/email-verifications/\(verificationId.uuidString)/verify",
            method: .post,
            bodyParameters: EmailVerificationCodeRequest(code: code)
        )
    }
}
