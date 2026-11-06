//
//  AnalyticsEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/analytics.md (STAT-01~05) 기준. from/to는 Asia/Seoul 오프셋이 포함된
//  타임스탬프 문자열을 그대로 전달한다(ISO8601 인코딩 전략이 아직 없어 Date를 쿼리 파라미터로
//  바로 넘기면 안 됨).
//

import Foundation

enum TrendBucket: String, Encodable {
    case day = "DAY"
    case month = "MONTH"
}

enum AnalyticsEndpoints {
    private struct SummaryQuery: Encodable {
        let from: String?
        let to: String?
        let subjectUserId: UUID?
    }

    private struct TrendsQuery: Encodable {
        let metric: String
        let bucket: TrendBucket
        let from: String?
        let to: String?
        let timeZone: String?
        let subjectUserId: UUID?
        let cursor: String?
        let limit: Int?
    }

    private struct MatchComparisonQuery: Encodable {
        let matchId: UUID
        let previousMatchId: UUID?
        let metric: String
    }

    private struct PositionsQuery: Encodable {
        let from: String?
        let to: String?
        let subjectUserId: UUID?
    }

    private struct FriendComparisonQuery: Encodable {
        let friendUserId: UUID
        let metric: String
        let from: String?
        let to: String?
    }

    /// STAT-01 경기 요약 지표 조회
    static func summary(from: String? = nil, to: String? = nil, subjectUserId: UUID? = nil) -> Endpoint<Envelope<SummaryResponse>> {
        Endpoint(
            path: "/api/v1/analytics/summary",
            method: .get,
            queryParameters: SummaryQuery(from: from, to: to, subjectUserId: subjectUserId)
        )
    }

    /// STAT-02 지표 추세 조회
    static func trends(
        metric: String,
        bucket: TrendBucket,
        from: String? = nil,
        to: String? = nil,
        timeZone: String? = nil,
        subjectUserId: UUID? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) -> Endpoint<PageEnvelope<TrendPointResponse>> {
        Endpoint(
            path: "/api/v1/analytics/trends",
            method: .get,
            queryParameters: TrendsQuery(
                metric: metric,
                bucket: bucket,
                from: from,
                to: to,
                timeZone: timeZone,
                subjectUserId: subjectUserId,
                cursor: cursor,
                limit: limit
            )
        )
    }

    /// STAT-03 경기 간 지표 비교
    static func matchComparison(matchId: UUID, previousMatchId: UUID? = nil, metric: String) -> Endpoint<Envelope<MatchComparisonResponse>> {
        Endpoint(
            path: "/api/v1/analytics/match-comparison",
            method: .get,
            queryParameters: MatchComparisonQuery(matchId: matchId, previousMatchId: previousMatchId, metric: metric)
        )
    }

    /// STAT-04 포지션 분석 조회
    static func positions(from: String? = nil, to: String? = nil, subjectUserId: UUID? = nil) -> Endpoint<Envelope<[PositionAnalysisResponse]>> {
        Endpoint(
            path: "/api/v1/analytics/positions",
            method: .get,
            queryParameters: PositionsQuery(from: from, to: to, subjectUserId: subjectUserId)
        )
    }

    /// STAT-05 친구와 지표 비교
    static func friendComparison(friendUserId: UUID, metric: String, from: String? = nil, to: String? = nil) -> Endpoint<Envelope<FriendComparisonResponse>> {
        Endpoint(
            path: "/api/v1/analytics/friend-comparison",
            method: .get,
            queryParameters: FriendComparisonQuery(friendUserId: friendUserId, metric: metric, from: from, to: to)
        )
    }
}
