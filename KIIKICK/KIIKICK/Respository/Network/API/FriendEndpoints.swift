//
//  FriendEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/friends.md (FRIEND-01~10) 기준.
//
//  DESIGN-GAP: 현재 Network 레이어에 Authorization 헤더 주입이 연결되어 있지 않다
//  (ProviderImpl/NetworkService 어디에도 Bearer 토큰 처리가 없음). 모든 friends.md
//  엔드포인트는 Authorization: Bearer <accessToken>을 요구하므로, 로그인 플로우가
//  실제 토큰을 발급하게 되면 이 레이어에 공통 주입 처리가 필요하다.
//

import Foundation

enum FriendEndpoints {
    private struct SearchQuery: Encodable {
        let query: String
        let cursor: String?
        let limit: Int?
    }

    private struct ListQuery: Encodable {
        let cursor: String?
        let limit: Int?
    }

    private struct FriendRequestListQuery: Encodable {
        let direction: FriendRequestDirection
        let cursor: String?
        let limit: Int?
    }

    /// FRIEND-01 친구 검색
    static func searchUsers(query: String, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<PublicProfileResponse>> {
        Endpoint(
            path: "/api/v1/users/search",
            method: .get,
            queryParameters: SearchQuery(query: query, cursor: cursor, limit: limit)
        )
    }

    /// FRIEND-02 친구·사용자 공개 프로필 조회
    static func profile(userId: UUID) -> Endpoint<Envelope<PublicProfileResponse>> {
        Endpoint(path: "/api/v1/users/\(userId.uuidString)/profile", method: .get)
    }

    /// FRIEND-03 내 친구 목록 조회
    static func listFriends(cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<FriendResponse>> {
        Endpoint(
            path: "/api/v1/friends",
            method: .get,
            queryParameters: ListQuery(cursor: cursor, limit: limit)
        )
    }

    /// FRIEND-04 보낸·받은 친구 요청 목록
    static func listFriendRequests(direction: FriendRequestDirection, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests",
            method: .get,
            queryParameters: FriendRequestListQuery(direction: direction, cursor: cursor, limit: limit)
        )
    }

    /// FRIEND-05 친구 요청 보내기
    static func sendFriendRequest(targetUserId: UUID) -> Endpoint<Envelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests",
            method: .post,
            bodyParameters: SendFriendRequestBody(targetUserId: targetUserId),
            headers: idempotencyHeaders()
        )
    }

    /// FRIEND-06 친구 요청 수락
    static func acceptFriendRequest(requestId: UUID) -> Endpoint<Envelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests/\(requestId.uuidString)/accept",
            method: .post,
            headers: idempotencyHeaders()
        )
    }

    /// FRIEND-07 친구 요청 취소·거절
    static func cancelOrRejectFriendRequest(requestId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/friend-requests/\(requestId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders()
        )
    }

    /// FRIEND-08 친구 삭제
    static func removeFriend(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/friends/\(userId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders()
        )
    }

    /// FRIEND-09 사용자 차단
    static func blockUser(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/users/\(userId.uuidString)/block",
            method: .put,
            headers: idempotencyHeaders()
        )
    }

    /// FRIEND-10 사용자 차단 해제
    static func unblockUser(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/users/\(userId.uuidString)/block",
            method: .delete,
            headers: idempotencyHeaders()
        )
    }
}
