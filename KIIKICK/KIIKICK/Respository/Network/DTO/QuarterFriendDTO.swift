//
//  QuarterFriendDTO.swift
//  KIIKICK
//

import Foundation

struct QuarterFriendResponse: Decodable, Equatable, Identifiable {
    let userId: UUID
    let nickname: String
    let avatarUrl: String?

    var id: UUID { userId }

    init(userId: UUID, nickname: String, avatarUrl: String?) {
        self.userId = userId
        self.nickname = nickname
        self.avatarUrl = avatarUrl
    }

    init(profile: UserProfile) {
        userId = profile.id
        nickname = profile.nickname
        avatarUrl = profile.avatarUrl
    }
}

struct VersionedMeta: Decodable {
    let requestId: UUID
    let serverTime: Date
    let matchVersion: Int
}

struct VersionedEnvelope<T: Decodable>: Decodable {
    let data: T
    let meta: VersionedMeta
}
