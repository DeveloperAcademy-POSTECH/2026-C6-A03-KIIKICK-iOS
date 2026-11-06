//
//  Friend.swift
//  KIIKICK
//

import Foundation

enum FriendshipStatus: Hashable {
    /// 이미 친구
    case friend
    /// 친구가 아님 (친구 추가 가능)
    case none
    /// 내가 친구 요청을 보내고 상대 응답을 기다리는 중
    case requestSent
}

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let nickname: String
    let avatarUrl: URL?
    var status: FriendshipStatus

    init(id: UUID = UUID(), nickname: String, status: FriendshipStatus, avatarUrl: URL? = nil) {
        self.id = id
        self.nickname = nickname
        self.status = status
        self.avatarUrl = avatarUrl
    }
}
