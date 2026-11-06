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
            queryParameters: PageQuery(cursor: cursor, limit: limit)
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
}
