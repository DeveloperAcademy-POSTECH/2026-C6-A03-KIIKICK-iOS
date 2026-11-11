import Foundation

@MainActor
enum FriendMatchLoader {
    static func load(userID: UUID, matchID: UUID, provider: any Provider) async throws -> FriendMatchAnalysis? {
        let result = try await provider.request(with: FriendMatchEndpoints.result(userID: userID, matchID: matchID))
        guard result.data.match.id == matchID, result.data.match.ownerId == userID else { throw NetworkError.decodeError }
        var cursor: String?
        var seen = Set<String>()
        var quarters: [QuarterResultResponse] = []
        repeat {
            let page = try await provider.request(with: FriendMatchEndpoints.quarters(userID: userID, matchID: matchID, cursor: cursor))
            try Task.checkCancellation()
            quarters.append(contentsOf: page.data)
            guard page.meta.pagination.hasNext else {
                var venue: VenueResponse?
                if quarters.allSatisfy({ $0.workout != nil }) && quarters.contains(where: { $0.workout?.field == nil }) {
                    venue = try? await provider.request(with: FriendMatchEndpoints.venue(userID: userID, matchID: matchID)).data
                }
                return FriendMatchAnalysis(result: result.data, quarters: quarters, venue: venue)
            }
            guard let next = page.meta.pagination.nextCursor, seen.insert(next).inserted else { throw NetworkError.components }
            cursor = next
        } while true
    }
}
