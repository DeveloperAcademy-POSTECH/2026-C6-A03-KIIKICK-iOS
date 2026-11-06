//
//  AnalyticsDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/analytics.md, docs/api/schemas.md의 Summary/TrendPoint/MatchComparison/
//  PositionAnalysis/FriendComparison 기준.
//

import Foundation

enum MetricAggregateStatus: String, Decodable {
    case ready = "READY"
    case incomplete = "INCOMPLETE"
    case noData = "NO_DATA"
    case policyRequired = "POLICY_REQUIRED"
}

struct MetricAggregate: Decodable {
    let value: Double?
    let includedQuarterCount: Int
    let totalQuarterCount: Int
    let status: MetricAggregateStatus
}

struct MetricCoverage: Decodable {
    let includedQuarterCount: Int
    let totalQuarterCount: Int
}

struct AnalyticsMeta: Decodable {
    let quarterCount: Int
    let missingStatsQuarterCount: Int
    let metricCoverage: [String: MetricCoverage]
    let calculationVersions: [String]
    let emptyReason: String?
}

struct SummaryResponse: Decodable {
    let matchCount: Int
    let quarterCount: Int
    let goals: Int?
    let assists: Int?
    let metrics: [String: MetricAggregate]
    let meta: AnalyticsMeta
}

struct TrendPointResponse: Decodable {
    let bucketStart: Date
    let bucketEnd: Date
    let metric: String
    let result: MetricAggregate
}

struct MatchComparisonResponse: Decodable {
    let current: SummaryResponse
    let previous: SummaryResponse?
    let metric: String
    let delta: Double?
}

struct PositionAnalysisResponse: Decodable {
    let positionCode: String?
    let quarterCount: Int
    let ratio: Double
}

struct FriendComparisonResponse: Decodable {
    let me: SummaryResponse
    let friend: SummaryResponse
    let metric: String
    let delta: Double?
}
