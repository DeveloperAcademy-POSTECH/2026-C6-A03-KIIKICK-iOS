//
//  QuarterDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/setup.md(SET-16~19), docs/api/gameplay.md(GAME-02,08~14),
//  docs/api/schemas.md의 Quarter/QuarterPlayerStats/PositionEntry 기준.
//

import Foundation

enum QuarterStatus: String, Decodable {
    case ready = "READY"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
}

struct QuarterResponse: Decodable, Identifiable {
    let id: UUID
    let matchId: UUID
    let number: Int
    let durationSeconds: Int
    let status: QuarterStatus
    let startedAt: Date?
    let endedAt: Date?
    let matchVersion: Int
    let createdAt: Date
    let updatedAt: Date
}

struct QuarterDurationRequest: Encodable {
    let durationSeconds: Int
}

struct QuarterPlayerStatsResponse: Decodable {
    let quarterId: UUID
    let goals: Int
    let assists: Int
    let updatedAt: Date
}

struct QuarterPlayerStatsRequest: Encodable {
    let goals: Int
    let assists: Int
}

struct PositionEntryResponse: Decodable {
    let quarterId: UUID
    let positionCode: String
    let updatedAt: Date
}

struct PositionEntryRequest: Encodable {
    let positionCode: String
}
