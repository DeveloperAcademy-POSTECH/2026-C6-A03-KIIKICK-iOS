import Foundation
import Observation

@MainActor @Observable
final class MatchCommentsModel {
    var draft = ""
    private(set) var comments: [MatchCommentResponse] = []
    private(set) var authors: [UUID: PublicProfileResponse] = [:]
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var hasNext = false
    private(set) var errorMessage: String?
    var replyTarget: Comment?
    private let matchID: UUID?
    private let provider: any Provider
    private var cursor: String?
    private var hasLoaded = false
    private var pending: (content: String, parentCommentID: UUID?, key: UUID)?
    private var repliesByCommentID: [UUID: [MatchCommentResponse]] = [:]
    private var loadedReplyCommentIDs = Set<UUID>()

    init(matchID: UUID?, provider: (any Provider)? = nil) {
        self.matchID = matchID
        self.provider = provider ?? NetworkService.provider
    }
    var canSend: Bool {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return matchID != nil && !isSending && !text.isEmpty && text.unicodeScalars.count <= 1000
    }
    var validationMessage: String? {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.count > 1000
            ? "댓글은 1000자 이내로 입력해 주세요" : nil
    }
    var displayedComments: [Comment] {
        comments.map { value in
            Comment(
                id: value.id,
                authorNickname: authors[value.authorId]?.nickname ?? "사용자",
                avatarURL: authors[value.authorId]?.avatarUrl,
                content: value.content,
                timestamp: value.createdAt.formatted(.relative(presentation: .named)),
                replies: (repliesByCommentID[value.id] ?? [])
                    .sorted { $0.createdAt < $1.createdAt }
                    .map { reply in
                        CommentReply(
                            id: reply.id,
                            authorNickname: authors[reply.authorId]?.nickname ?? "사용자",
                            avatarURL: authors[reply.authorId]?.avatarUrl,
                            content: reply.content,
                            timestamp: reply.createdAt.formatted(.relative(presentation: .named))
                        )
                    }
            )
        }
    }

    var commentCount: Int {
        comments.count + repliesByCommentID.values.reduce(0) { $0 + $1.count }
    }

    func beginReply(to comment: Comment) {
        replyTarget = comment
        draft = ""
        pending = nil
    }

    func cancelReply() {
        replyTarget = nil
        draft = ""
        pending = nil
    }
    func loadInitial() async {
        guard !hasLoaded else { return }
        await loadMore()
    }
    func loadMore() async {
        guard let matchID, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page = try await provider.request(with: MatchCommentEndpoints.list(matchID: matchID, cursor: cursor))
            try Task.checkCancellation()
            let next = page.meta.pagination.nextCursor
            if page.meta.pagination.hasNext && (next == nil || next == cursor) { throw NetworkError.components }
            var existing = Set(comments.map(\.id))
            let newComments = page.data.filter {
                $0.matchId == matchID && $0.parentCommentId == nil && existing.insert($0.id).inserted
            }
            comments.append(contentsOf: newComments)
            comments.sort { $0.createdAt > $1.createdAt }
            cursor = next
            hasNext = page.meta.pagination.hasNext
            hasLoaded = true
            await loadAuthors(for: newComments)
            // 댓글 목록 재시도 시에도 아직 로드하지 못한 답글을 다시 요청한다.
            for comment in comments where !loadedReplyCommentIDs.contains(comment.id) {
                await loadReplies(for: comment.id)
            }
        } catch {
            guard !Task.isCancelled else { return }
            clearOnAccessLoss(error)
            errorMessage = "댓글을 불러오지 못했어요. 다시 시도해 주세요"
        }
    }
    func send() async {
        guard let matchID, canSend else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let parentCommentID = replyTarget?.id
        if pending?.content != content || pending?.parentCommentID != parentCommentID {
            pending = (content, parentCommentID, UUID())
        }
        guard let pending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let response = try await provider.request(with: MatchCommentEndpoints.create(
                matchID: matchID,
                content: content,
                parentCommentID: pending.parentCommentID,
                idempotencyKey: pending.key
            ))
            try Task.checkCancellation()
            guard response.data.matchId == matchID else { throw NetworkError.decodeError }
            let responseParentID = response.data.parentCommentId ?? pending.parentCommentID
            if let responseParentID {
                var replies = repliesByCommentID[responseParentID] ?? []
                if !replies.contains(where: { $0.id == response.data.id }) {
                    replies.append(response.data)
                    repliesByCommentID[responseParentID] = replies.sorted { $0.createdAt < $1.createdAt }
                }
                loadedReplyCommentIDs.insert(responseParentID)
            } else if !comments.contains(where: { $0.id == response.data.id }) {
                comments.insert(response.data, at: 0)
            }
            self.pending = nil
            if draft.trimmingCharacters(in: .whitespacesAndNewlines) == content { draft = "" }
            replyTarget = nil
            await loadAuthors(for: [response.data])
        } catch {
            guard !Task.isCancelled else { return }
            clearOnAccessLoss(error)
            errorMessage = "댓글을 전송하지 못했어요. 입력한 내용은 유지했으니 다시 시도해 주세요"
        }
    }
    private func loadAuthors(for comments: [MatchCommentResponse]) async {
        for id in Set(comments.map(\.authorId)) where authors[id] == nil {
            guard !Task.isCancelled else { return }
            if let response = try? await provider.request(with: FriendEndpoints.profile(userId: id)), response.data.id == id {
                authors[id] = response.data
            }
        }
    }

    private func loadReplies(for parentCommentID: UUID) async {
        guard let matchID, !loadedReplyCommentIDs.contains(parentCommentID) else { return }

        var cursor: String?
        var loaded: [MatchCommentResponse] = []
        do {
            while true {
                let page = try await provider.request(with: MatchCommentEndpoints.listReplies(
                    matchID: matchID,
                    parentCommentID: parentCommentID,
                    cursor: cursor
                ))
                try Task.checkCancellation()
                loaded.append(contentsOf: page.data.filter {
                    $0.matchId == matchID && $0.parentCommentId == parentCommentID
                })
                guard page.meta.pagination.hasNext else { break }
                guard let next = page.meta.pagination.nextCursor, next != cursor else {
                    throw NetworkError.components
                }
                cursor = next
            }

            var existing = repliesByCommentID[parentCommentID] ?? []
            var seen = Set(existing.map(\.id))
            existing.append(contentsOf: loaded.filter { seen.insert($0.id).inserted })
            repliesByCommentID[parentCommentID] = existing.sorted { $0.createdAt < $1.createdAt }
            loadedReplyCommentIDs.insert(parentCommentID)
            await loadAuthors(for: loaded)
        } catch {
            guard !Task.isCancelled else { return }
            clearOnAccessLoss(error)
            errorMessage = "답글을 불러오지 못했어요. 다시 시도해 주세요"
        }
    }

    private func clearOnAccessLoss(_ error: Error) {
        if case let NetworkError.invalidHttpStatusCode(status, _) = error, [403, 404].contains(status) {
            comments = []
            authors = [:]
            cursor = nil
            hasNext = false
            hasLoaded = false
            replyTarget = nil
            repliesByCommentID = [:]
            loadedReplyCommentIDs = []
        }
    }
}
