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

    static var userId: UUID? {
        guard let value = KeychainService.get(key: userIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    static var isLoggedIn: Bool { userId != nil }

    static var nickname: String? {
        get { UserDefaults.standard.string(forKey: nicknameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nicknameKey) }
    }

    static func save(userId: UUID, nickname: String) {
        _ = KeychainService.add(key: userIdKey, value: userId.uuidString)
        self.nickname = nickname
    }

    static func clear() {
        _ = KeychainService.delete(key: userIdKey)
        UserDefaults.standard.removeObject(forKey: nicknameKey)
    }
}
