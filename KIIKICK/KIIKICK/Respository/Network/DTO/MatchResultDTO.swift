//
//  MatchResultDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/results.md (RESULT-01/03/04), docs/api/schemas.md의 Match/Quarter/
//  QuarterResult/MatchResult 기준. 경기·쿼터 결과 응답의 meta는 공통 ResponseMeta/PageMeta에
//  matchVersion이 추가된 형태라 전용 meta/envelope 타입을 둔다. Match/Quarter/
//  QuarterPlayerStats/PositionEntry는 MatchDTO.swift·QuarterDTO.swift에 이미 정의되어
//  있으므로 그대로 재사용한다.
//

import Foundation

enum QuarterSummaryCalculationStatus: String, Codable {
    case processing = "PROCESSING"
    case partial = "PARTIAL"
    case ready = "READY"
    case failed = "FAILED"
}

struct ResultWorkout: Codable {
    let id: UUID
    let quarterId: UUID
    let startDate: Date
    let endDate: Date
    let totalCalories: Double
    let totalDistance: Double
    var events: [ResultWorkoutEvent]? = nil
    var field: WorkoutFieldPayload? = nil
}

struct MetricStatusEntry: Codable {
    let status: String
    let reason: String?
}

struct QuarterSummary: Codable {
    let quarterId: UUID
    let workoutPayloadId: UUID
    let calculationStatus: QuarterSummaryCalculationStatus
    let calculationVersion: String
    let metricStatus: [String: MetricStatusEntry]
    let durationSeconds: Double?
    let maxSpeedMps: Double?
    let totalDistanceM: Double?
    let totalCaloriesKcal: Double?
    let averageSpeedMps: Double?
    let highIntensityDistanceM: Double?
    let accelerationCount: Int?
    let decelerationCount: Int?
    let directionChangeCount: Int?
    let averageHeartRateBpm: Double?
    let maxHeartRateBpm: Double?
    let trimpEdwards: Double?
    let hrMaxReferenceBpm: Double?
    let validHrDurationSeconds: Double?
    let validGpsDurationSeconds: Double?
    let calculatedAt: Date?
    let updatedAt: Date
}

struct QuarterResultResponse: Codable {
    let quarter: QuarterResponse
    let stats: QuarterPlayerStatsResponse?
    let position: PositionEntryResponse?
    let workout: ResultWorkout?
    let summary: QuarterSummary?
}

struct SummaryAvailability: Codable {
    let ready: Int
    let partial: Int
    let processing: Int
    let failed: Int
    let missing: Int
}

struct MatchResultResponse: Codable {
    let match: MatchResponse
    let quarterCount: Int
    let goals: Int?
    let assists: Int?
    let missingStatsQuarterIds: [UUID]
    let summaryAvailability: SummaryAvailability
}

struct MatchResultMeta: Decodable {
    let requestId: UUID
    let serverTime: Date
    let matchVersion: Int?
}

struct MatchResultEnvelope<T: Decodable>: Decodable {
    let data: T
    let meta: MatchResultMeta
}

struct MatchResultPageMeta: Decodable {
    let requestId: UUID
    let serverTime: Date
    let pagination: Pagination
    let matchVersion: Int?
}

struct MatchResultPageEnvelope<T: Decodable>: Decodable {
    let data: [T]
    let meta: MatchResultPageMeta
}
