import Foundation

enum MatchCommentEndpoints {
    private struct PageQuery: Encodable { let cursor: String?; let limit: Int }
    private struct ReplyPageQuery: Encodable {
        let parentCommentId: UUID
        let cursor: String?
        let limit: Int
    }
    private struct CreateCommentBody: Encodable { let content: String }
    private struct CreateReplyBody: Encodable { let content: String; let parentCommentId: UUID }

    static func list(matchID: UUID, cursor: String? = nil) -> Endpoint<PageEnvelope<MatchCommentResponse>> {
        Endpoint(path: "/api/v1/matches/\(matchID)/comments", method: .get,
            queryParameters: PageQuery(cursor: cursor, limit: 20), headers: bearerHeaders())
    }
    static func listReplies(
        matchID: UUID,
        parentCommentID: UUID,
        cursor: String? = nil
    ) -> Endpoint<PageEnvelope<MatchCommentResponse>> {
        Endpoint(path: "/api/v1/matches/\(matchID)/comments", method: .get,
            queryParameters: ReplyPageQuery(parentCommentId: parentCommentID, cursor: cursor, limit: 100),
            headers: bearerHeaders())
    }

    static func create(
        matchID: UUID,
        content: String,
        parentCommentID: UUID? = nil,
        idempotencyKey: UUID
    ) -> Endpoint<Envelope<MatchCommentResponse>> {
        // Swagger에는 string으로 표시되지만 실제 응답은 201 {data: CommentResponse, meta}다.
        let body: Encodable = if let parentCommentID {
            CreateReplyBody(content: content, parentCommentId: parentCommentID)
        } else {
            CreateCommentBody(content: content)
        }
        return Endpoint<Envelope<MatchCommentResponse>>(path: "/api/v1/matches/\(matchID)/comments", method: .post,
            bodyParameters: body,
            headers: bearerHeaders().merging(["Idempotency-Key": idempotencyKey.uuidString]) { $1 })
    }
    /// #75: 삭제 API만 준비한다. 삭제 버튼/액션은 연결하지 않는다.
    static func delete(matchID: UUID, commentID: UUID, idempotencyKey: UUID) -> Endpoint<Void> {
        Endpoint(path: "/api/v1/matches/\(matchID)/comments/\(commentID)", method: .delete,
            headers: bearerHeaders().merging(["Idempotency-Key": idempotencyKey.uuidString]) { $1 })
    }
}
