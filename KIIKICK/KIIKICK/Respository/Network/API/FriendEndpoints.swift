//
//  FriendEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/friends.md (FRIEND-01~10) 기준.
//
//  이슈 #65: 실제 화면에 연결하면서 Authorization도 전부 붙였다(AuthHeader.swift의
//  bearerHeaders()). Idempotency-Key/If-Match는 Swagger상 전부 선택이라
//  idempotencyHeaders()만 유지한다.
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
            queryParameters: SearchQuery(query: query, cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }
    
    /// FRIEND-02 친구·사용자 공개 프로필 조회
    static func profile(userId: UUID) -> Endpoint<Envelope<PublicProfileResponse>> {
        Endpoint(path: "/api/v1/users/\(userId.uuidString)/profile", method: .get, headers: bearerHeaders())
    }
    
    /// FRIEND-03 내 친구 목록 조회
    static func listFriends(cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<FriendResponse>> {
        Endpoint(
            path: "/api/v1/friends",
            method: .get,
            queryParameters: ListQuery(cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }
    
    /// FRIEND-04 보낸·받은 친구 요청 목록
    static func listFriendRequests(direction: FriendRequestDirection, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests",
            method: .get,
            queryParameters: FriendRequestListQuery(direction: direction, cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }
    
    /// FRIEND-05 친구 요청 보내기
    static func sendFriendRequest(targetUserId: UUID) -> Endpoint<Envelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests",
            method: .post,
            bodyParameters: SendFriendRequestBody(targetUserId: targetUserId),
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
    
    /// FRIEND-06 친구 요청 수락
    static func acceptFriendRequest(requestId: UUID) -> Endpoint<Envelope<FriendRequestResponse>> {
        Endpoint(
            path: "/api/v1/friend-requests/\(requestId.uuidString)/accept",
            method: .post,
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
    
    /// FRIEND-07 친구 요청 취소·거절
    static func cancelOrRejectFriendRequest(requestId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/friend-requests/\(requestId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
    
    /// FRIEND-08 친구 삭제
    static func removeFriend(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/friends/\(userId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
    
    /// FRIEND-09 사용자 차단 — 연결할 뷰가 아직 없다(이슈 #65 표에 "없음"). 엔드포인트만 둔다.
    static func blockUser(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/users/\(userId.uuidString)/block",
            method: .put,
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
    
    /// FRIEND-10 사용자 차단 해제 — 연결할 뷰가 아직 없다(이슈 #65 표에 "없음").
    static func unblockUser(userId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/users/\(userId.uuidString)/block",
            method: .delete,
            headers: idempotencyHeaders().merging(bearerHeaders()) { _, new in new }
        )
    }
}
