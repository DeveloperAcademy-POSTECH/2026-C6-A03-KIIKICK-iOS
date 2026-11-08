//
//  MatchEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/setup.md (SET-06~11), docs/api/gameplay.md (GAME-01,12) 기준.
//
//  DESIGN-GAP: 변경 대상 경기를 다시 쓰는 요청(PATCH/ready/cancel/start/end)은 문서상
//  최신 경기 ETag를 If-Match로 보내야 한다. 하지만 현재 ProviderImpl은 응답 HTTP 헤더를
//  읽지 않으므로(상태 코드만 검사하고 버림) 호출자가 서버가 실제로 내려준 ETag를 얻을
//  방법이 아직 없다. 당장은 호출자가 가진 값(예: 직전 GET 응답의 meta.matchVersion 등)을
//  ifMatch 파라미터로 그대로 전달하도록 열어 두고, Provider가 응답 헤더를 노출하게 되면
//  이 부분을 실제 ETag 값으로 교체한다.
//

import Foundation

enum MatchEndpoints {
    private struct ListQuery: Encodable {
        let status: MatchStatus?
        let cursor: String?
        let limit: Int?
    }

    /// SET-06 내 경기 목록
    static func list(status: MatchStatus? = nil, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches",
            method: .get,
            queryParameters: ListQuery(status: status, cursor: cursor, limit: limit)
        )
    }

    /// SET-07 개인 경기 묶음 생성
    static func create(
        title: String? = nil,
        venueId: UUID? = nil,
        venueSnapshot: VenueSnapshot? = nil,
        scheduledAt: Date? = nil
    ) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches",
            method: .post,
            bodyParameters: MatchCreateRequest(
                title: title,
                venueId: venueId,
                venueSnapshot: venueSnapshot,
                scheduledAt: scheduledAt.map(rfc3339SeoulString)
            ),
            headers: idempotencyHeaders()
        )
    }

    /// SET-08 경기 상세·최신 버전
    static func detail(matchId: UUID) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(path: "/api/v1/matches/\(matchId.uuidString)", method: .get)
    }

    /// SET-09 경기 설정 수정
    static func update(
        matchId: UUID,
        title: String? = nil,
        venueId: UUID? = nil,
        venueSnapshot: VenueSnapshot? = nil,
        scheduledAt: Date? = nil,
        ifMatch: String
    ) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)",
            method: .patch,
            bodyParameters: MatchUpdateRequest(
                title: title,
                venueId: venueId,
                venueSnapshot: venueSnapshot,
                scheduledAt: scheduledAt.map(rfc3339SeoulString)
            ),
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// SET-10 경기 준비 완료 (DRAFT -> READY)
    static func ready(matchId: UUID, ifMatch: String) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/ready",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// SET-11 시작 전 경기 취소 (DRAFT/READY -> CANCELLED)
    static func cancel(matchId: UUID, ifMatch: String) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/cancel",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-01 경기 시작 (READY -> IN_PROGRESS)
    static func start(matchId: UUID, ifMatch: String) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/start",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }

    /// GAME-12 경기 묶음 종료 (IN_PROGRESS -> COMPLETED)
    static func end(matchId: UUID, ifMatch: String) -> Endpoint<Envelope<MatchResponse>> {
        Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString)/end",
            method: .post,
            headers: idempotencyHeaders().merging(["If-Match": ifMatch]) { $1 }
        )
    }
}
