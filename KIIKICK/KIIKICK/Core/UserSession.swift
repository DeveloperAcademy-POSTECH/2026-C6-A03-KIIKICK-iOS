//
//  UserSession.swift
//  KIIKICK
//
//  로그인한 사용자의 UserId를 Keychain에 UUID 형식으로 저장/조회한다.
//  닉네임과 프로필 이미지 URL은 로그인·프로필 조회·수정 시 로컬에 함께 캐싱한다.
//

import Foundation
import OSLog
import UIKit

enum UserSession {
    private static let userIdKey = "userId"
    private static let nicknameKey = "nickname"
    static let avatarUrlKey = "profileAvatarUrl"
    static let avatarRevisionKey = "profileAvatarRevision"
    private static let tokenKey = "accessToken"
    private static let refreshTokenKey = "refreshToken"
    private static let sessionIdKey = "sessionId"
    private static let tokenExpiresAtKey = "accessTokenExpiresAt"
    private(set) static var profileVersion = 0
    private static let logger = Logger(subsystem: "KIIKICK", category: "Profile")

    static var userId: UUID? {
        guard let value = KeychainService.get(key: userIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    /// AuthEndpoints.login/signup/refresh로 받은 실제 accessToken.
    static var token: String? { KeychainService.get(key: tokenKey) }

    static var refreshToken: String? { KeychainService.get(key: refreshTokenKey) }

    /// AuthEndpoints.login/signup/refresh 응답의 expiresAt — accessToken 만료 판단용.
    private static var tokenExpiresAt: Date? {
        get { UserDefaults.standard.object(forKey: tokenExpiresAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: tokenExpiresAtKey) }
    }

    /// 만료 시각을 모르는 토큰(이 필드가 생기기 전에 저장된 세션)은 만료된 것으로 취급해
    /// 재인증을 한 번 시도하게 한다.
    private static var isAccessTokenExpired: Bool {
        guard let tokenExpiresAt else { return true }
        return Date() >= tokenExpiresAt
    }

    /// 로그아웃(AuthEndpoints.logout) 대상 세션 ID — 생략하면 서버가 현재 토큰의 세션으로 처리한다.
    static var sessionId: UUID? {
        guard let value = KeychainService.get(key: sessionIdKey) else { return nil }
        return UUID(uuidString: value)
    }

    static var isLoggedIn: Bool { userId != nil || token != nil }

    static var nickname: String? {
        get { UserDefaults.standard.string(forKey: nicknameKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: nicknameKey)
            profileVersion += 1
        }
    }

    static var avatarUrl: String? {
        get { UserDefaults.standard.string(forKey: avatarUrlKey) }
        set {
            UserAvatarImageStore.shared.clear()
            UserDefaults.standard.set(newValue, forKey: avatarUrlKey)
            UserDefaults.standard.set(UUID().uuidString, forKey: avatarRevisionKey)
            profileVersion += 1
        }
    }

    static var avatarImageKey: String? {
        let revision = UserDefaults.standard.string(forKey: avatarRevisionKey) ?? ""
        return avatarImageCacheKey(url: avatarUrl ?? "", revision: revision)
    }

    static func avatarImageCacheKey(url: String, revision: String) -> String? {
        guard let userId, !url.isEmpty else { return nil }
        return "\(userId.uuidString)|\(url)|\(revision)"
    }

    /// accessToken이 만료됐으면 refreshToken으로 재인증한다 — 앱 진입(RootView)과 홈 화면
    /// 진입(HomeView) 두 트리거에서 호출한다. refreshToken이 없거나 재인증 자체가
    /// 실패하면(서버가 refreshToken도 거부) 세션을 지우고 false를 반환한다 — 호출부는
    /// 이를 로그아웃으로 처리해야 한다.
    @discardableResult
    static func reauthenticateIfNeeded() async -> Bool {
        guard token != nil else { return false }
        guard isAccessTokenExpired else { return true }
        guard let refreshToken else {
            clear()
            return false
        }
        do {
            let result = try await NetworkService.provider.request(with: AuthEndpoints.refresh(refreshToken: refreshToken))
            save(session: result.data)
            return true
        } catch {
            clear()
            return false
        }
    }

    static func refreshProfile() async throws {
        guard let ownerId = userId, token != nil else { return }
        let version = profileVersion
        do {
            let profile = try await NetworkService.provider.request(with: AuthEndpoints.profile())
            try Task.checkCancellation()
            guard userId == ownerId, profileVersion == version else { return }
            update(profile: profile.data)
        } catch {
            if !Task.isCancelled {
                logger.error("프로필 조회 실패. 저장된 프로필을 유지합니다.")
            }
            throw error
        }
    }

    /// 조회 중 계정이 바뀌면 이전 계정 응답을 현재 프로필에 적용하지 않는다.
    static func update(profile: AuthUserResponse) {
        guard userId == profile.id else { return }
        nickname = profile.nickname
        if avatarUrl != profile.avatarUrl {
            avatarUrl = profile.avatarUrl
        }
    }

    static func saveAvatar(url: String, for ownerId: UUID, imageData: Data? = nil) {
        guard userId == ownerId else { return }
        // 같은 URL로 사진을 교체해도 화면이 이미지를 다시 가져오도록 revision을 바꾼다.
        avatarUrl = url
        // 업로드한 이미지는 서버에서 다시 받지 않고 모든 화면에서 즉시 재사용한다.
        if let imageData, let image = UIImage(data: imageData), let key = avatarImageKey {
            UserAvatarImageStore.shared.store(image: image, data: imageData, key: key)
        }
    }

    static func save(userId: UUID, nickname: String) {
        if self.userId != userId { avatarUrl = nil }
        _ = KeychainService.add(key: userIdKey, value: userId.uuidString)
        self.nickname = nickname
    }

    static func saveToken(_ token: String) {
        _ = KeychainService.add(key: tokenKey, value: token)
    }

    /// 로그인/회원가입/갱신 응답(SessionResponse) 하나로 세션 전체를 저장한다.
    static func save(session: SessionResponse) {
        let previousUserId = userId
        let previousAvatarUrl = avatarUrl
        _ = KeychainService.add(key: userIdKey, value: session.user.id.uuidString)
        _ = KeychainService.add(key: tokenKey, value: session.accessToken)
        _ = KeychainService.add(key: refreshTokenKey, value: session.refreshToken)
        _ = KeychainService.add(key: sessionIdKey, value: session.sessionId.uuidString)
        tokenExpiresAt = session.expiresAt
        nickname = session.user.nickname
        if previousUserId != session.user.id || previousAvatarUrl != session.user.avatarUrl {
            avatarUrl = session.user.avatarUrl
        }
    }

    static func clear() {
        _ = KeychainService.delete(key: userIdKey)
        _ = KeychainService.delete(key: tokenKey)
        _ = KeychainService.delete(key: refreshTokenKey)
        _ = KeychainService.delete(key: sessionIdKey)
        UserDefaults.standard.removeObject(forKey: nicknameKey)
        UserDefaults.standard.removeObject(forKey: tokenExpiresAtKey)
        avatarUrl = nil
    }
}
