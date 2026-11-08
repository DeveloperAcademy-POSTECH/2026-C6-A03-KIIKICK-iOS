import Foundation
import Observation

@MainActor
@Observable
final class FriendSearchModel {
    private(set) var results: [UserProfile] = []
    private(set) var isSearching = false

    func prepare(for query: String) {
        results = []
        isSearching = !query.isEmpty
    }

    func search(_ request: FriendSearchRequest) async {
        guard !request.query.isEmpty else {
            prepare(for: request.query)
            return
        }
        isSearching = true
        do {
            try await Task.sleep(for: .milliseconds(200))
            try Task.checkCancellation()
            results = request.users.filter { $0.nickname.localizedStandardContains(request.query) }
            isSearching = false
        } catch is CancellationError {
            // 취소된 검색은 다음 검색의 결과나 로딩 상태를 덮어쓰지 않는다.
        } catch {
            isSearching = false
        }
    }
}
