import CoreLocation
import Foundation
import SwiftUI

/// 업로드가 끝난 본인 경기만 분석 탭에 복원한다.
struct OwnMatchAnalysisSnapshot: Codable {
    let result: MatchResultResponse
    let quarters: [QuarterResultResponse]
    let pointsByQuarter: [UUID: [TrackPointResponse]]
}

@MainActor
enum OwnMatchAnalysisLoader {
    static func load(excluding knownIDs: Set<UUID>, provider: (any Provider)? = nil) async throws -> [OwnMatchAnalysisSnapshot] {
        let provider = provider ?? NetworkService.provider
        var matches: [MatchResponse] = []
        var cursor: String?
        var seenCursors = Set<String>()
        repeat {
            let page = try await provider.request(with: MatchEndpoints.list(status: .completed, cursor: cursor, limit: 100))
            matches += page.data
            guard page.meta.pagination.hasNext else { break }
            guard let next = page.meta.pagination.nextCursor, seenCursors.insert(next).inserted else {
                throw NetworkError.components
            }
            cursor = next
        } while true

        var snapshots: [OwnMatchAnalysisSnapshot] = []
        for match in matches where !knownIDs.contains(match.id) {
            try Task.checkCancellation()
            do {
                guard let snapshot = try await loadMatch(match.id, provider: provider) else { continue }
                snapshots.append(snapshot)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // 다른 경기 하나의 조회 실패가 전체 목록을 가리지 않게 한다.
                continue
            }
        }
        return snapshots
    }

    private static func loadMatch(_ id: UUID, provider: any Provider) async throws -> OwnMatchAnalysisSnapshot? {
        let response = try await provider.request(with: MatchResultEndpoints.matchResult(matchId: id))
        var quarters: [QuarterResultResponse] = []
        var cursor: String?
        var seenCursors = Set<String>()
        repeat {
            let page = try await provider.request(with: MatchResultEndpoints.quarterResults(matchId: id, cursor: cursor, limit: 100))
            quarters += page.data
            guard page.meta.pagination.hasNext else { break }
            guard let next = page.meta.pagination.nextCursor, seenCursors.insert(next).inserted else {
                throw NetworkError.components
            }
            cursor = next
        } while true
        // 현재 workout-submissions는 분석 보기에서만 호출된다. 완전한 제출 결과만 목록에 둔다.
        guard FriendMatchAnalysis(result: response.data, quarters: quarters) != nil else { return nil }
        var pointsByQuarter: [UUID: [TrackPointResponse]] = [:]
        for quarter in quarters {
            pointsByQuarter[quarter.quarter.id] = try await loadPoints(quarterID: quarter.quarter.id, provider: provider)
        }
        return OwnMatchAnalysisSnapshot(result: response.data, quarters: quarters, pointsByQuarter: pointsByQuarter)
    }

    static func entry(from snapshot: OwnMatchAnalysisSnapshot) -> AnalysisEntry? {
        guard let base = FriendMatchAnalysis(result: snapshot.result, quarters: snapshot.quarters)?.entry else { return nil }
        let resultsByID = Dictionary(uniqueKeysWithValues: snapshot.quarters.map { ($0.quarter.id, $0) })
        var restored: [AnalysisQuarter] = []
        for quarter in base.detail.quarters {
            guard let result = resultsByID[quarter.id] else { return nil }
            let points = (snapshot.pointsByQuarter[quarter.id] ?? []).map { value in
                TrackPoint(latitude: value.latitude, longitude: value.longitude, altitude: value.altitude,
                    horizontalAccuracy: value.horizontalAccuracy, speed: value.speed,
                    course: value.course, timestamp: value.timestamp)
            }
            let events = (result.workout?.events ?? []).compactMap { event -> AnalysisMatchEvent? in
                guard let location = event.location else { return nil }
                let timestamp = Date(timeIntervalSinceReferenceDate: location.timestamp)
                let position: UnitPoint
                if let field = quarter.field {
                    let normalized = FieldCoordinateMapper(field: field).normalize(
                        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    position = UnitPoint(x: normalized.x, y: normalized.y)
                } else {
                    position = UnitPoint(x: 0.5, y: 0.5)
                }
                let type: TimelineEventType = event.type == "goal" ? .goal : .assist
                let elapsed = timestamp.timeIntervalSince(result.workout?.startDate ?? timestamp)
                let minutes = max(0, Int(elapsed)) / 60
                let seconds = max(0, Int(elapsed)) % 60
                return AnalysisMatchEvent(type: type, timeText: String(format: "%02d:%02d", minutes, seconds),
                    timestamp: timestamp, position: position)
            }
            var item = AnalysisQuarter(id: quarter.id, quarterNumber: quarter.quarterNumber,
                durationText: quarter.durationText, startDate: result.workout?.startDate,
                duration: result.workout.map { $0.endDate.timeIntervalSince($0.startDate) } ?? 0,
                position: quarter.position, field: quarter.field, points: points, events: events,
                totalDistanceKm: quarter.totalDistanceKm, totalCaloriesKcal: quarter.totalCaloriesKcal)
            item.resultStats = quarter.resultStats
            item.resultSections = quarter.resultSections
            item.resultGoals = quarter.resultGoals
            item.resultAssists = quarter.resultAssists
            restored.append(item)
        }
        let detail = base.detail
        return AnalysisEntry(id: snapshot.result.match.id, date: base.date, dateAndQuarter: base.dateAndQuarter,
            fieldName: base.fieldName, stats: base.stats,
            detail: AnalysisDetail(id: detail.id, title: detail.title, quarters: restored,
                keyStats: detail.keyStats, goalCount: detail.goalCount, assistCount: detail.assistCount,
                sections: detail.sections, disclaimer: "히트맵과 포지션이 정확한지 확인해주세요"))
    }

    private static func loadPoints(quarterID: UUID, provider: any Provider) async throws -> [TrackPointResponse] {
        var points: [TrackPointResponse] = []
        var cursor: String?
        var seenCursors = Set<String>()
        repeat {
            let page = try await provider.request(with: QuarterWorkoutEndpoints.trackPoints(
                quarterId: quarterID, cursor: cursor, limit: 100))
            points += page.data
            guard page.meta.pagination.hasNext else { break }
            guard let next = page.meta.pagination.nextCursor, seenCursors.insert(next).inserted else {
                throw NetworkError.components
            }
            cursor = next
        } while true
        return points
    }
}
