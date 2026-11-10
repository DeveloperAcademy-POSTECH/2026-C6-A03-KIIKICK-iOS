import Foundation

/// 서버 MatchCommentController.CommentResponse. 작성자는 별도 공개 프로필로 표시한다.
struct MatchCommentResponse: Decodable, Identifiable {
    let id: UUID
    let matchId: UUID
    let authorId: UUID
    let content: String
    let createdAt: Date
}
