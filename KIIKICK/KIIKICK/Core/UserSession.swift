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

    static var userId: UUID? {
        guard let value = KeychainService.get(key: userIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    /// 로그인/회원가입 API가 아직 없어(변경 예정) 실제 토큰이 아니라 mock 값이 저장된다.
    static var token: String? { KeychainService.get(key: tokenKey) }

    /// 기존 화면은 UUID를 임시 토큰으로 저장한다. 아바타 API는 실제 인증 세션에서만 사용한다.
    static var accessToken: String? {
        guard let token, token.split(separator: ".").count == 3 else { return nil }
        return token
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

    static func clear() {
        _ = KeychainService.delete(key: userIdKey)
        _ = KeychainService.delete(key: tokenKey)
        UserDefaults.standard.removeObject(forKey: nicknameKey)
    }
}
