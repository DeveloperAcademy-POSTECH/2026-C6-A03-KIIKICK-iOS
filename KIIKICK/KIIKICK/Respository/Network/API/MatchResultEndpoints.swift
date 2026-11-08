//
//  MatchResultEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/results.md (RESULT-01/03/04) 기준. RESULT-02(참여자별 결과)는 문서상
//  제거된 계약이라 구현하지 않는다.
//

import Foundation

enum MatchResultEndpoints {
    private struct QuartersQuery: Encodable {
        let cursor: String?
        let limit: Int?
    }
    
    /// RESULT 개별 쿼터 결과 조회
    static func quarterResult(quarterId: UUID) -> Endpoint<MatchResultEnvelope<QuarterResultResponse>> {
        Endpoint(path: "/api/v1/quarters/\(quarterId.uuidString)/result", method: .get)
    }
    
    /// RESULT  개인 경기 결과 조회
    static func matchResult(matchId: UUID) -> Endpoint<MatchResultEnvelope<MatchResultResponse>> {
        Endpoint(path: "/api/v1/matches/\(matchId.uuidString)/result", method: .get)
    }
    
    /// RESULT 경기 내 쿼터별 결과 조회
    static func quarterResults(matchId: UUID, cursor: String? = nil, limit: Int? = nil) -> Endpoint<MatchResultPageEnvelope<QuarterResultResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/result/quarters",
            method: .get,
            queryParameters: QuartersQuery(cursor: cursor, limit: limit)
        )
    }
}
