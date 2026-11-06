//
//  FriendDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/friends.md (FRIEND-01~10), docs/api/schemas.md의
//  PublicProfile/Friend/FriendRequest 기준.
//

import Foundation

enum FriendRelationship: String, Decodable {
    case none = "NONE"
    case pendingSent = "PENDING_SENT"
    case pendingReceived = "PENDING_RECEIVED"
    case friend = "FRIEND"
    case blocked = "BLOCKED"
}

struct PublicProfileResponse: Decodable {
    let id: UUID
    let nickname: String
    let avatarUrl: String?
    let relationship: FriendRelationship
}

struct FriendResponse: Decodable {
    let profile: PublicProfileResponse
    let friendsSince: Date
}

enum FriendRequestDirection: String, Encodable {
    case sent = "SENT"
    case received = "RECEIVED"
}

/// FriendRequest.status. UI에 이미 있는 FriendRequestStatus(NotificationFriendView)와
/// 이름이 겹치지 않도록 FriendRequestState로 명명.
enum FriendRequestState: String, Decodable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
}

struct FriendRequestResponse: Decodable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    let status: FriendRequestState
    let createdAt: Date
}

struct SendFriendRequestBody: Encodable {
    let targetUserId: UUID
}
