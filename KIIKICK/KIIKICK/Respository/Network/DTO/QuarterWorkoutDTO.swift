//
//  QuarterWorkoutDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/workouts.md (WORK-01~07), docs/api/schemas.md의 TrackPoint/HeartRateSample 기준.
//  Workout/QuarterSummary/Envelope(matchVersion 포함)는 MatchResultDTO.swift에 이미 정의된
//  ResultWorkout/QuarterSummary/MatchResultEnvelope를 그대로 재사용한다(중복 정의 금지).
//  업로드(WORK-01) 요청 본문은 "KIIKICK Global"의 WorkoutPayload를 그대로 재사용한다 —
//  Apple epoch Double 초 형식은 Codable Date의 기본(.deferredToDate) 인코딩과 일치한다.
//

import Foundation

/// WORK-04 GPS 원본 페이지 조회 응답 원소. 조회 응답의 timestamp는 +09:00 서울 시각 문자열로,
/// 업로드 요청의 Apple epoch Double과 다르므로 별도 타입을 둔다.
struct TrackPointResponse: Codable {
    let sampleSeq: Int
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let horizontalAccuracy: Double
    let speed: Double
    let course: Double
    let timestamp: Date
}

/// WORK-05 심박 원본 페이지 조회 응답 원소.
struct HeartRateSampleResponse: Decodable {
    let sampleSeq: Int
    let timestamp: Date
    let bpm: Double
}

/// WORK-06 Edwards 기준 최대심박수 설정 요청 본문.
struct HrMaxReferenceRequest: Encodable {
    let hrMaxReferenceBpm: Double
}

/// 이슈 #66: 완료 경기의 운동 기록과 포지션 일괄 제출(quarter-workout-controller의
/// 4번째 엔드포인트, POST /matches/{matchId}/workout-submissions) 요청 본문의 쿼터 원소.
/// `workout`은 Swagger의 WorkoutPayloadCreateRequest와 동일한 모양이라(WORK-01과 같은
/// 이유) WorkoutPayload를 그대로 재사용한다.
struct SubmissionQuarter: Encodable {
    /// Swift의 UUID.uuidString은 대문자인데 Swagger 예시는 전부 소문자라, 호출부가
    /// .lowercased()로 넘긴다 — String으로 받아서 그 값을 그대로 보낸다.
    let quarterId: String
    /// 서버에 설정된 대표 포지션 코드.
    let position: String
    let workout: WorkoutPayload
}

struct SubmissionBody: Encodable {
    let quarters: [SubmissionQuarter]
}

/// 응답의 meta는 MatchResultEnvelope가 쓰는 MatchResultMeta와 모양이 같아 그대로 재사용한다.
struct SubmissionReceipt: Decodable {
    let matchId: UUID
    let quarterCount: Int
}
