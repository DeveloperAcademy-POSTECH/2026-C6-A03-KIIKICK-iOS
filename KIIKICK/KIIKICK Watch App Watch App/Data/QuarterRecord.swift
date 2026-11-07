//
//  QuarterRecord.swift
//  KIIKICK Watch App Watch App
//
//  쿼터 하나가 끝날 때마다 로컬 SwiftData에 저장되는 기록이자, 그 쿼터 하나를 그대로
//  나타내는 WorkoutPayload의 전송 단위. 전송이 성공하면 SessionManager가 같은 id로 지운다.
//

import Foundation
import SwiftData

@Model
final class QuarterRecord {
    var id: UUID
    var quarterNumber: Int
    var position: Position
    var startDate: Date
    var endDate: Date
    var points: [TrackPoint]
    var heartRateSamples: [HeartRateSample]
    var goalCount: Int
    var assistCount: Int
    var events: [MatchEvent]

    init(
        id: UUID = UUID(),
        quarterNumber: Int,
        position: Position,
        startDate: Date,
        endDate: Date,
        points: [TrackPoint],
        heartRateSamples: [HeartRateSample],
        goalCount: Int,
        assistCount: Int,
        events: [MatchEvent]
    ) {
        self.id = id
        self.quarterNumber = quarterNumber
        self.position = position
        self.startDate = startDate
        self.endDate = endDate
        self.points = points
        self.heartRateSamples = heartRateSamples
        self.goalCount = goalCount
        self.assistCount = assistCount
        self.events = events
    }
}
