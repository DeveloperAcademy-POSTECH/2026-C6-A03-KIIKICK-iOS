import Foundation

/// 워치 payload 대신 생성한 목업 경기를 기존 분석 플로우의 WorkoutRecord로 변환한다.
enum MockHeatmapWorkoutRecordFactory {
    static func records(
        from match: MockHeatmapMatch,
        position: MockHeatmapPosition,
        field: Field
    ) -> [WorkoutRecord] {
        guard let player = match.players.first else { return [] }
        let matchID = UUID()

        return player.quarters.map { quarter in
            let analysisQuarter = MockHeatmapAnalysisAdapter.quarter(quarter)
            let points = analysisQuarter.points
            let events = quarter.events.compactMap { event -> MatchEvent? in
                guard let point = quarter.points[safe: event.pointIndex] else { return nil }
                return MatchEvent(
                    type: event.type == .goal ? .goal : .assist,
                    location: MockHeatmapAnalysisAdapter.trackPoint(point)
                )
            }
            let startDate = analysisQuarter.startDate ?? match.startedAt
            let payload = WorkoutPayload(
                startDate: startDate,
                endDate: startDate.addingTimeInterval(quarter.duration),
                points: points,
                heartRateSamples: quarter.points.map {
                    HeartRateSample(timestamp: $0.timestamp, bpm: $0.heartRateBpm)
                },
                totalCalories: MockHeatmapAnalysisAdapter.caloriesKcal(for: quarter),
                totalDistance: MockHeatmapAnalysisAdapter.totalDistanceMeters(quarter.points),
                events: events,
                position: position.workoutPosition
            )
            let record = WorkoutRecord(payload: payload)
            record.field = field
            record.position = position.workoutPosition
            record.matchId = matchID
            return record
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
