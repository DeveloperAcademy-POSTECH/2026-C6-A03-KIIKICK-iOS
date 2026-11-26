import Foundation

/// 서버 MatchCommentController.CommentResponse. 작성자는 별도 공개 프로필로 표시한다.
struct MatchCommentResponse: Decodable, Identifiable {
    let id: UUID
    let matchId: UUID
    let authorId: UUID
    let content: String
    let createdAt: Date
    /// 답글인 경우에만 포함되는 부모 댓글 ID.
    let parentCommentId: UUID?
}
