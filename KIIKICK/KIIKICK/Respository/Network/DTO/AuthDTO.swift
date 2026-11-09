//
//  AuthDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/auth.md는 OAuth 제공자 토큰 교환(AUTH-01 exchange) 설계를 담고 있는데,
//  실제 배포된 Swagger(/v3/api-docs)는 이메일 인증 → 회원가입/로그인 방식으로 완전히
//  다르게 구현돼 있다. 문서가 실제 구현을 못 따라간 상태라 이 파일은 Swagger 스키마를
//  그대로 따른다 (SignupRequest/LoginRequest/.. 등 제네릭 타입 소거가 없는 구체 DTO라
//  Notification 때 겪은 Page<T> 오탐 문제는 없음).
//

import Foundation

struct EmailVerificationRequest: Encodable {
    let email: String
}

struct EmailVerificationResponse: Decodable {
    let verificationId: UUID
    let expiresAt: Date
    let resendAvailableAt: Date
}

struct EmailVerificationCodeRequest: Encodable {
    let code: String
}

struct EmailVerificationSuccessResponse: Decodable {
    /// 회원가입(AuthEndpoints.signup)에 그대로 넘기는 토큰.
    let registrationToken: String
    let expiresAt: Date
}

struct SignupRequest: Encodable {
    let registrationToken: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct LogoutRequest: Encodable {
    /// 생략하면 서버가 현재 access token의 세션을 대상으로 처리한다.
    let sessionId: UUID?
}

enum OnboardingStatus: String, Decodable {
    case required = "REQUIRED"
    case completed = "COMPLETED"
}

/// signup/login/refresh의 `user`와 GET·PATCH /users/me의 응답이 동일한 모양이라 공유한다.
struct AuthUserResponse: Decodable {
    let id: UUID
    let nickname: String?
    let avatarUrl: String?
    let onboardingStatus: OnboardingStatus
    let comparisonConsent: Bool
    let createdAt: Date
}

struct SessionResponse: Decodable {
    let sessionId: UUID
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUserResponse
}

struct ProfilePatchRequest: Encodable {
    let nickname: String?
    /// nil은 "값을 보내지 않음"으로 인코딩된다(Swift Encodable의 encodeIfPresent 기본 동작) —
    /// 스웨거 설명상 null은 "이미지 제거"를 뜻하지만, 지금 구조로는 명시적 null 전송과
    /// 필드 생략을 구분할 수 없다. 아바타 삭제는 /users/me/avatar DELETE로 대신 처리한다.
    let avatarUrl: String?
}
