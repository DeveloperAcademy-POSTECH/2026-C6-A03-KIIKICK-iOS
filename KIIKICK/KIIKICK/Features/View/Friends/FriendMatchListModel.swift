import Foundation
import Observation

@MainActor @Observable
final class FriendMatchListModel {
    private(set) var entries: [FriendMatchAnalysis] = []
    private(set) var isLoading = false
    private(set) var hasNext = false
    private(set) var errorMessage: String?
    private let userID: UUID
    private let provider: any Provider
    private var cursor: String?

    init(userID: UUID, provider: (any Provider)? = nil) {
        self.userID = userID
        self.provider = provider ?? NetworkService.provider
    }
    func clear() { entries = []; cursor = nil; hasNext = false; errorMessage = nil }
    func reload() async {
        guard !isLoading else { return }
        clear()
        await loadMore()
    }
    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var seenCursors = Set(cursor.map { [$0] } ?? [])
            repeat {
                let page = try await provider.request(with: FriendMatchEndpoints.list(userID: userID, cursor: cursor))
                var added: [FriendMatchAnalysis] = []
                for match in page.data where match.status == .completed && match.ownerId == userID {
                    try Task.checkCancellation()
                    do {
                        if let entry = try await FriendMatchLoader.load(userID: userID, matchID: match.id, provider: provider) {
                            added.append(entry)
                        }
                    } catch NetworkError.invalidHttpStatusCode(404, _) {
                        // 조회 도중 삭제되거나 비공개 상태가 된 경기는 노출하지 않는다.
                    } catch NetworkError.invalidHttpStatusCode(409, _) {
                        // 아직 완료 결과가 준비되지 않은 경기.
                    }
                }
                try Task.checkCancellation()
                let next = page.meta.pagination.nextCursor
                if page.meta.pagination.hasNext {
                    guard let next, seenCursors.insert(next).inserted else { throw NetworkError.components }
                }
                var existing = Set(entries.map(\.id))
                entries.append(contentsOf: added.filter { existing.insert($0.id).inserted })
                entries.sort { $0.entry.date > $1.entry.date }
                cursor = next
                hasNext = page.meta.pagination.hasNext
                if !added.isEmpty { break }
            } while hasNext
        } catch {
            guard !Task.isCancelled else { return }
            if case NetworkError.invalidHttpStatusCode(403, _) = error { clear() }
            if case NetworkError.invalidHttpStatusCode(404, _) = error { clear() }
            errorMessage = "친구의 경기 기록을 불러오지 못했어요. 다시 시도해 주세요"
        }
    }
}
