//
//  QuarterEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/setup.md (SET-16~19), docs/api/gameplay.md (GAME-02,08~11,13,14) 기준.
//
//  DESIGN-GAP: MatchEndpoints.swift와 동일한 이유로, 쿼터를 변경하는 요청들도 최신 경기
//  ETag를 If-Match로 보내야 하지만 Provider가 아직 응답 헤더를 노출하지 않는다. ifMatch는
//  호출자가 가진 값을 그대로 전달하는 임시 파라미터이며, 추후 Provider가 헤더를 노출하면
//  실제 ETag로 교체한다.
//

import Foundation

enum QuarterEndpoints {
    private struct ListQuery: Encodable {
        let cursor: String?
        let limit: Int?
    }

    /// SET-16 쿼터 목록
    static func list(matchId: UUID, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters",
            method: .get,
            queryParameters: ListQuery(cursor: cursor, limit: limit)
        )
    }

    /// SET-17 쿼터 추가
    static func create(matchId: UUID, durationSeconds: Int, ifMatch: String) -> Endpoint<Envelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters",
            method: .post,
            bodyParameters: QuarterDurationRequest(durationSeconds: durationSeconds),
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// SET-18 미시작 쿼터 시간 수정
    static func updateDuration(matchId: UUID, quarterId: UUID, durationSeconds: Int, ifMatch: String) -> Endpoint<Envelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)",
            method: .patch,
            bodyParameters: QuarterDurationRequest(durationSeconds: durationSeconds),
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// SET-19 미사용 마지막 쿼터 삭제
    static func delete(matchId: UUID, quarterId: UUID, ifMatch: String) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-02 쿼터 시작
    static func start(matchId: UUID, quarterId: UUID, ifMatch: String) -> Endpoint<Envelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/start",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-08 쿼터 측정 마감
    static func endMeasurement(matchId: UUID, quarterId: UUID, ifMatch: String) -> Endpoint<Envelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/end",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-11 쿼터 완료 확정
    static func complete(matchId: UUID, quarterId: UUID, ifMatch: String) -> Endpoint<Envelope<QuarterResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/complete",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-09 쿼터 대표 포지션 조회 (미입력 시 data=null)
    static func position(matchId: UUID, quarterId: UUID) -> Endpoint<Envelope<PositionEntryResponse?>> {
        Endpoint(path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/position", method: .get)
    }

    /// GAME-10 쿼터 대표 포지션 저장·수정
    static func setPosition(matchId: UUID, quarterId: UUID, positionCode: String, ifMatch: String) -> Endpoint<Envelope<PositionEntryResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/position",
            method: .put,
            bodyParameters: PositionEntryRequest(positionCode: positionCode),
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-13 쿼터 골·어시스트 조회 (미입력 시 data=null)
    static func stats(matchId: UUID, quarterId: UUID) -> Endpoint<Envelope<QuarterPlayerStatsResponse?>> {
        Endpoint(path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/stats", method: .get)
    }

    /// GAME-14 쿼터 골·어시스트 합계 저장·수정
    static func setStats(matchId: UUID, quarterId: UUID, goals: Int, assists: Int, ifMatch: String) -> Endpoint<Envelope<QuarterPlayerStatsResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/quarters/\(quarterId.uuidString)/stats",
            method: .put,
            bodyParameters: QuarterPlayerStatsRequest(goals: goals, assists: assists),
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }
}
