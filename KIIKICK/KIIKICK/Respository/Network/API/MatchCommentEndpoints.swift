import Foundation

enum MatchCommentEndpoints {
    private struct PageQuery: Encodable { let cursor: String?; let limit: Int }
    private struct CreateBody: Encodable { let content: String }

    static func list(matchID: UUID, cursor: String? = nil) -> Endpoint<PageEnvelope<MatchCommentResponse>> {
        Endpoint(path: "/api/v1/matches/\(matchID)/comments", method: .get,
            queryParameters: PageQuery(cursor: cursor, limit: 20), headers: bearerHeaders())
    }
    static func create(matchID: UUID, content: String, idempotencyKey: UUID) -> Endpoint<Envelope<MatchCommentResponse>> {
        // Swagger에는 string으로 표시되지만 실제 응답은 201 {data: CommentResponse, meta}다.
        Endpoint(path: "/api/v1/matches/\(matchID)/comments", method: .post,
            bodyParameters: CreateBody(content: content),
            headers: bearerHeaders().merging(["Idempotency-Key": idempotencyKey.uuidString]) { $1 })
    }
    /// #75: 삭제 API만 준비한다. 삭제 버튼/액션은 연결하지 않는다.
    static func delete(matchID: UUID, commentID: UUID, idempotencyKey: UUID) -> Endpoint<Void> {
        Endpoint(path: "/api/v1/matches/\(matchID)/comments/\(commentID)", method: .delete,
            headers: bearerHeaders().merging(["Idempotency-Key": idempotencyKey.uuidString]) { $1 })
    }
}
