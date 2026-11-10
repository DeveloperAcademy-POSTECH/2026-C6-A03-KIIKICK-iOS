//
//  WorkoutRecord.swift
//  KIIKICK
//

import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var date: Date
    var duration: TimeInterval
    var totalCalories: Double
    var totalDistance: Double
    var points: [TrackPoint]
    var heartRateSamples: [HeartRateSample]
    var events: [MatchEvent] = []
    var field: Field?
    /// 워치 PositionView에서 고른 포지션. 강제 종료된 쿼터(이슈 #50)는 nil.
    var position: Position?
    var isAttackDirectionReversed: Bool = false
    /// 분석 준비에서 ‘분석 보기’를 눌러 설정을 저장했는지 여부.
    var hasViewedAnalysis: Bool = false

    // 이슈 #66: POST /matches/{matchId}/workout-submissions에 보낼 식별자. 서버 매치
    // 생성 플로우(MatchEndpoints.create 등)가 아직 로컬 녹화와 연결돼 있지 않아서
    // (DESIGN-GAP) iOS가 직접 만든 UUID를 그대로 보낸다. quarterId는 레코드(쿼터)마다
    // 새로 만들고, matchId는 같은 경기로 묶인 레코드들끼리
    // AnalysisEntry.build(from:)에서 맞춰준다(harmonize) — 묶이기 전까지는 레코드마다 다르다.
    var matchId: UUID = UUID()
    var quarterId: UUID = UUID()

    init(payload: WorkoutPayload) {
        self.date = payload.startDate
        self.duration = payload.endDate.timeIntervalSince(payload.startDate)
        self.totalCalories = payload.totalCalories
        self.totalDistance = payload.totalDistance
        self.points = payload.points
        self.heartRateSamples = payload.heartRateSamples
        self.events = payload.events
        self.position = payload.position
    }
}

#if DEBUG
extension WorkoutPayload {
    static func fake() -> WorkoutPayload {
        let baseLatitude = 37.5665
        let baseLongitude = 126.9780
        let start = Date().addingTimeInterval(-600)
        let sampleCount = 120
        
        var points: [TrackPoint] = []
        var heartRateSamples: [HeartRateSample] = []
        
        for i in 0..<sampleCount {
            let timestamp = start.addingTimeInterval(Double(i) * 5)
            let angle = Double(i) * 0.15
            points.append(TrackPoint(
                latitude: baseLatitude + sin(angle) * 0.0004,
                longitude: baseLongitude + cos(angle) * 0.0004,
                altitude: 20,
                horizontalAccuracy: 5,
                speed: Double.random(in: 0...5),
                course: angle.truncatingRemainder(dividingBy: .pi * 2) * 180 / .pi,
                timestamp: timestamp
            ))
            heartRateSamples.append(HeartRateSample(timestamp: timestamp, bpm: Double.random(in: 90...170)))
        }

        let events: [MatchEvent] = [
            MatchEvent(type: .goal, location: points[sampleCount / 3]),
            MatchEvent(type: .assist, location: points[sampleCount * 2 / 3]),
        ]

        return WorkoutPayload(
            startDate: start,
            endDate: start.addingTimeInterval(Double(sampleCount) * 5),
            points: points,
            heartRateSamples: heartRateSamples,
            totalCalories: Double.random(in: 300...600),
            totalDistance: Double.random(in: 2000...4000),
            events: events
        )
    }
}
#endif
