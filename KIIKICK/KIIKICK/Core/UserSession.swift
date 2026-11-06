//
//  UserSession.swift
//  KIIKICK
//
//  로그인한 사용자의 UserId를 Keychain에 UUID 형식으로 저장/조회한다.
//  닉네임은 개인 사용자 조회 API를 안 쓰기로 해서, 로그인/수정 시점에 로컬에 같이 캐싱해둔다.
//

import Foundation

enum UserSession {
    private static let userIdKey = "userId"
    private static let nicknameKey = "nickname"
    private static let tokenKey = "accessToken"
    private static let refreshTokenKey = "refreshToken"
    private static let sessionIdKey = "sessionId"

    static var userId: UUID? {
        guard let value = KeychainService.get(key: userIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    /// AuthEndpoints.login/signup/refresh로 받은 실제 accessToken.
    static var token: String? { KeychainService.get(key: tokenKey) }

    static var refreshToken: String? { KeychainService.get(key: refreshTokenKey) }

    /// 로그아웃(AuthEndpoints.logout) 대상 세션 ID — 생략하면 서버가 현재 토큰의 세션으로 처리한다.
    static var sessionId: UUID? {
        guard let value = KeychainService.get(key: sessionIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    static var isLoggedIn: Bool { userId != nil || token != nil }

    static var nickname: String? {
        get { UserDefaults.standard.string(forKey: nicknameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nicknameKey) }
    }

    static func save(userId: UUID, nickname: String) {
        _ = KeychainService.add(key: userIdKey, value: userId.uuidString)
        self.nickname = nickname
    }

    static func saveToken(_ token: String) {
        _ = KeychainService.add(key: tokenKey, value: token)
    }

    /// 로그인/회원가입/갱신 응답(SessionResponse) 하나로 세션 전체를 저장한다.
    static func save(session: SessionResponse) {
        _ = KeychainService.add(key: userIdKey, value: session.user.id.uuidString)
        _ = KeychainService.add(key: tokenKey, value: session.accessToken)
        _ = KeychainService.add(key: refreshTokenKey, value: session.refreshToken)
        _ = KeychainService.add(key: sessionIdKey, value: session.sessionId.uuidString)
        nickname = session.user.nickname
    }

    static func clear() {
        _ = KeychainService.delete(key: userIdKey)
        _ = KeychainService.delete(key: tokenKey)
        _ = KeychainService.delete(key: refreshTokenKey)
        _ = KeychainService.delete(key: sessionIdKey)
        UserDefaults.standard.removeObject(forKey: nicknameKey)
    }
}
