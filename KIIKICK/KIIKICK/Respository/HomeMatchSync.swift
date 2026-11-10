import Foundation

struct HomeSyncedMatch {
    let id: UUID
    let status: MatchStatus
    let workouts: [OverallWorkout]
    let totalDistanceMeters: Double
    let totalCalories: Double
    let quarterCount: Int
}

/// 로컬 쿼터를 먼저 유지하고, 로그인 계정의 서버 경기 결과를 홈에 반영한다.
@MainActor
enum HomeMatchSync {
    static func load(provider: Provider? = nil) async throws -> [HomeSyncedMatch] {
        let provider = provider ?? NetworkService.provider
        let matches = try await fetchMatches(provider: provider)
        var result: [HomeSyncedMatch] = []
        for match in matches {
            guard match.status == .completed else {
                result.append(HomeSyncedMatch(id: match.id, status: match.status, workouts: [], totalDistanceMeters: 0, totalCalories: 0, quarterCount: 0))
                continue
            }
            let quarters = try await fetchQuarters(matchID: match.id, provider: provider)
            let workouts = quarters.compactMap { quarter -> OverallWorkout? in
                guard let summary = quarter.summary, let date = quarter.quarter.startedAt,
                      let duration = summary.durationSeconds,
                      let distance = summary.totalDistanceM,
                      let speed = summary.maxSpeedMps,
                      let acceleration = summary.accelerationCount,
                      let deceleration = summary.decelerationCount,
                      let calories = summary.totalCaloriesKcal else { return nil }
                return OverallWorkout(date: date, durationSeconds: duration, distanceMeters: distance,
                    peakSpeedKmh: speed * 3.6, accelerationCount: acceleration,
                    decelerationCount: deceleration, calories: calories)
            }
            result.append(HomeSyncedMatch(
                id: match.id, status: match.status, workouts: workouts,
                totalDistanceMeters: quarters.reduce(0) { $0 + ($1.workout?.totalDistance ?? $1.summary?.totalDistanceM ?? 0) },
                totalCalories: quarters.reduce(0) { $0 + ($1.workout?.totalCalories ?? $1.summary?.totalCaloriesKcal ?? 0) },
                quarterCount: quarters.count
            ))
        }
        return result
    }

    private static func fetchMatches(provider: Provider) async throws -> [MatchResponse] {
        var result: [MatchResponse] = []
        var cursor: String?
        repeat {
            let page = try await provider.request(with: MatchEndpoints.list(status: .completed, cursor: cursor, limit: 100))
            result += page.data
            cursor = page.meta.pagination.hasNext ? page.meta.pagination.nextCursor : nil
        } while cursor != nil
        return result
    }

    private static func fetchQuarters(matchID: UUID, provider: Provider) async throws -> [QuarterResultResponse] {
        var result: [QuarterResultResponse] = []
        var cursor: String?
        repeat {
            let page = try await provider.request(with: MatchResultEndpoints.quarterResults(matchId: matchID, cursor: cursor, limit: 100))
            result += page.data
            cursor = page.meta.pagination.hasNext ? page.meta.pagination.nextCursor : nil
        } while cursor != nil
        return result
    }

}
