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
    /// 이슈 #65: 상대가 나한테 먼저 친구 요청을 보낸 상태(FriendRelationship.pendingReceived) —
    /// 검색/프로필에서 만날 수 있다. 수락/거절은 알림 탭에서 하므로 여기서는 "응답을
    /// 기다리는 요청이 와 있다"는 안내만 보여준다.
    case pendingReceived
    /// 이슈 #65: 차단한 상대(FriendRelationship.blocked). 친구 추가 버튼을 숨긴다.
    case blocked

    /// 서버 응답(PublicProfileResponse.relationship)을 로컬 표시 상태로 옮긴다.
    init(relationship: FriendRelationship) {
        switch relationship {
        case .none: self = .none
        case .pendingSent: self = .requestSent
        case .pendingReceived: self = .pendingReceived
        case .friend: self = .friend
        case .blocked: self = .blocked
        }
    }
}

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    let nickname: String
    var status: FriendshipStatus
    var avatarUrl: String?

    init(id: UUID = UUID(), nickname: String, status: FriendshipStatus, avatarUrl: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.status = status
        self.avatarUrl = avatarUrl
    }

    init(response: PublicProfileResponse) {
        self.id = response.id
        self.nickname = response.nickname
        self.status = FriendshipStatus(relationship: response.relationship)
        self.avatarUrl = response.avatarUrl
    }
}
