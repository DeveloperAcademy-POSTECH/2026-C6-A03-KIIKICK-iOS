import Foundation

enum FriendMatchEndpoints {
    private struct ListQuery: Encodable {
        let status = MatchStatus.completed.rawValue
        let cursor: String?
        let limit: Int
    }
    private struct PageQuery: Encodable {
        let cursor: String?
        let limit: Int
    }
    static func list(userID: UUID, cursor: String? = nil) -> Endpoint<PageEnvelope<MatchResponse>> {
        Endpoint(path: "/api/v1/friends/\(userID)/matches", method: .get,
            queryParameters: ListQuery(cursor: cursor, limit: 20), headers: bearerHeaders())
    }
    static func result(userID: UUID, matchID: UUID) -> Endpoint<MatchResultEnvelope<MatchResultResponse>> {
        Endpoint(path: "/api/v1/friends/\(userID)/matches/\(matchID)/result", method: .get, headers: bearerHeaders())
    }
    static func quarters(userID: UUID, matchID: UUID, cursor: String? = nil) -> Endpoint<MatchResultPageEnvelope<QuarterResultResponse>> {
        Endpoint(path: "/api/v1/friends/\(userID)/matches/\(matchID)/result/quarters", method: .get,
            queryParameters: PageQuery(cursor: cursor, limit: 100), headers: bearerHeaders())
    }

    static func venue(userID: UUID, matchID: UUID) -> Endpoint<MatchResultEnvelope<VenueResponse>> {
        Endpoint(path: "/api/v1/friends/\(userID.uuidString.lowercased())/matches/\(matchID.uuidString.lowercased())/venue",
            method: .get, headers: bearerHeaders())
    }

    /// 친구의 원본 GPS 대신 익명화·집계된 격자 밀도를 반환한다.
    static func heatmap(userID: UUID, matchID: UUID, quarterID: UUID) -> Endpoint<FriendHeatmapEnvelope> {
        Endpoint(
            path: "/api/v1/friends/\(userID.uuidString.lowercased())/matches/\(matchID.uuidString.lowercased())/quarters/\(quarterID.uuidString.lowercased())/heatmap",
            method: .get,
            headers: bearerHeaders()
        )
    }
}
