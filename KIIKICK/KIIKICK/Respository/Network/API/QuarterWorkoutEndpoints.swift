//
//  QuarterWorkoutEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/workouts.md (WORK-01~07) 기준.
//
//  DESIGN-GAP: 현재 Provider/ProviderImpl은 응답 HTTPURLResponse의 헤더를 전혀 읽지
//  않고 버린다(ProviderImpl.execute가 status code만 검증하고 Data만 반환). 그래서 서버가
//  돌려주는 최신 ETag를 자동으로 캡처해 다음 If-Match에 쓸 방법이 아직 없다. 임시로
//  이 쿼터/경기 변경 엔드포인트들은 호출자가 ifMatch 문자열을 직접 넘기도록 두고,
//  Provider가 응답 헤더를 노출하게 되면 이 부분을 자동 캡처로 교체한다.
//

import Foundation

enum QuarterWorkoutEndpoints {
    private struct PageQuery: Encodable {
        let cursor: String?
        let limit: Int?
    }

    private static func ifMatchHeaders(_ ifMatch: String) -> [String: String] {
        idempotencyHeaders().merging(["If-Match": ifMatch]) { _, new in new }
    }

    /// submit(이슈 #66) 전용 — ifMatch가 nil이면 헤더를 아예 생략한다. 최초 제출(서버에
    /// 아직 등록되지 않은 경기) 때는 버전을 알 수 없어 헤더 생략을 허용하고, 이미
    /// 등록된 경기는 호출부가 MatchEndpoints.detail로 미리 조회한 최신 version을 넘긴다.
    private static func optionalIfMatchHeaders(_ ifMatch: String?) -> [String: String] {
        var headers = idempotencyHeaders()
        if let ifMatch { headers["If-Match"] = ifMatch }
        return headers
    }

    /// WORK-01 쿼터 운동 원본 업로드. 본문은 "KIIKICK Global"의 WorkoutPayload를 그대로 쓴다.
    static func uploadPayload(
        quarterId: UUID,
        payload: WorkoutPayload,
        ifMatch: String
    ) -> Endpoint<MatchResultEnvelope<ResultWorkout>> {
        Endpoint(
            path: "/api/v1/quarters/\(quarterId.uuidString)/workout-payloads",
            method: .post,
            bodyParameters: payload,
            headers: ifMatchHeaders(ifMatch)
        )
    }

    /// WORK-02 저장 운동 기본값 조회.
    static func workout(quarterId: UUID) -> Endpoint<Envelope<ResultWorkout>> {
        Endpoint(path: "/api/v1/quarters/\(quarterId.uuidString)/workout", method: .get)
    }

    /// WORK-03 쿼터 운동 요약 조회. 원본 미수신이면 data=null.
    static func summary(quarterId: UUID) -> Endpoint<MatchResultEnvelope<QuarterSummary?>> {
        Endpoint(path: "/api/v1/quarters/\(quarterId.uuidString)/summary", method: .get)
    }

    /// WORK-04 GPS 원본 페이지 조회. sampleSeq 오름차순.
    static func trackPoints(quarterId: UUID, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<TrackPointResponse>> {
        Endpoint(
            path: "/api/v1/quarters/\(quarterId.uuidString)/track-points",
            method: .get,
            queryParameters: PageQuery(cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }

    /// WORK-05 심박 원본 페이지 조회. sampleSeq 오름차순.
    static func heartRateSamples(quarterId: UUID, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<HeartRateSampleResponse>> {
        Endpoint(
            path: "/api/v1/quarters/\(quarterId.uuidString)/heart-rate-samples",
            method: .get,
            queryParameters: PageQuery(cursor: cursor, limit: limit)
        )
    }

    /// WORK-06 Edwards 기준 최대심박수 설정. 재계산을 트리거하고 202로 QuarterSummary를 반환한다.
    static func updateSummarySettings(
        quarterId: UUID,
        hrMaxReferenceBpm: Double,
        ifMatch: String
    ) -> Endpoint<MatchResultEnvelope<QuarterSummary>> {
        Endpoint(
            path: "/api/v1/quarters/\(quarterId.uuidString)/summary/settings",
            method: .put,
            bodyParameters: HrMaxReferenceRequest(hrMaxReferenceBpm: hrMaxReferenceBpm),
            headers: ifMatchHeaders(ifMatch)
        )
    }

    /// WORK-07 운동 요약 재계산 요청. 본문 없음, 202로 QuarterSummary를 반환한다.
    static func recalculateSummary(quarterId: UUID, ifMatch: String) -> Endpoint<MatchResultEnvelope<QuarterSummary>> {
        Endpoint(
            path: "/api/v1/quarters/\(quarterId.uuidString)/summary/recalculate",
            method: .post,
            headers: ifMatchHeaders(ifMatch)
        )
    }

    /// 이슈 #66: quarter-workout-controller의 4번째 엔드포인트만 연동한다 — 완료 경기의
    /// 운동 기록과 포지션을 일괄 제출. 서버 매치 생성 플로우가 로컬 녹화와 아직
    /// 연결되지 않아서(WorkoutRecord.matchId 주석 참고) matchId는 호출부(iOS가 만든 값)를
    /// 그대로 받는다.
    ///
    /// If-Match는 "내가 아는 경기 버전과 서버 현재 버전이 같을 때만 처리해 달라"는
    /// 낙관적 동시성 헤더다 — 분석 결과가 저장될 때도 경기 버전이 올라가므로 이전 값을
    /// 재사용하면 412가 난다. 호출부가 제출 직전에 MatchEndpoints.detail로 최신
    /// version을 조회해서 `ifMatch`로 넘긴다. 아직 서버에 등록되지 않은 경기(최초
    /// 제출)는 버전을 모르니 nil을 넘기면 헤더 자체를 생략한다.
    ///
    /// 이 엔드포인트는 다른 match/quarter 계열과 달리 Authorization을 직접 붙인다 —
    /// DevAuthView("로그인 화면 보기")로 실제 로그인해서 받은 토큰이 여기서 처음으로
    /// 쓰인다. AuthHeader.swift 주석의 DESIGN-GAP(다른 도메인은 아직 미적용)은 그대로
    /// 유효하다 — 이 엔드포인트 하나만 먼저 붙였다.
    static func submit(matchId: UUID, quarters: [SubmissionQuarter], ifMatch: String?, idempotencyKey: UUID? = nil) -> Endpoint<MatchResultEnvelope<SubmissionReceipt>> {
        var headers = optionalIfMatchHeaders(ifMatch).merging(bearerHeaders()) { _, new in new }
        if let idempotencyKey { headers["Idempotency-Key"] = idempotencyKey.uuidString }
        return Endpoint(
            path: "/api/v1/matches/\(matchId.uuidString.lowercased())/workout-submissions",
            method: .post,
            bodyParameters: SubmissionBody(quarters: quarters),
            headers: headers
        )
    }
}
