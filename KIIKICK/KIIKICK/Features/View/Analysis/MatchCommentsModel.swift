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
    private let matchID: UUID?
    private let provider: any Provider
    private var cursor: String?
    private var hasLoaded = false
    private var pending: (content: String, key: UUID)?

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
            Comment(id: value.id, authorNickname: authors[value.authorId]?.nickname ?? "사용자",
                avatarURL: authors[value.authorId]?.avatarUrl,
                content: value.content, timestamp: value.createdAt.formatted(.relative(presentation: .named)))
        }
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
            comments.append(contentsOf: page.data.filter { $0.matchId == matchID && existing.insert($0.id).inserted })
            comments.sort { $0.createdAt > $1.createdAt }
            cursor = next
            hasNext = page.meta.pagination.hasNext
            hasLoaded = true
            await loadAuthors(for: page.data)
        } catch {
            guard !Task.isCancelled else { return }
            clearOnAccessLoss(error)
            errorMessage = "댓글을 불러오지 못했어요. 다시 시도해 주세요"
        }
    }
    func send() async {
        guard let matchID, canSend else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if pending?.content != content { pending = (content, UUID()) }
        guard let pending else { return }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            let response = try await provider.request(with: MatchCommentEndpoints.create(
                matchID: matchID, content: content, idempotencyKey: pending.key))
            try Task.checkCancellation()
            guard response.data.matchId == matchID else { throw NetworkError.decodeError }
            if !comments.contains(where: { $0.id == response.data.id }) { comments.insert(response.data, at: 0) }
            self.pending = nil
            if draft.trimmingCharacters(in: .whitespacesAndNewlines) == content { draft = "" }
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
    private func clearOnAccessLoss(_ error: Error) {
        if case let NetworkError.invalidHttpStatusCode(status, _) = error, [403, 404].contains(status) {
            comments = []; authors = [:]; cursor = nil; hasNext = false; hasLoaded = false
        }
    }
}
