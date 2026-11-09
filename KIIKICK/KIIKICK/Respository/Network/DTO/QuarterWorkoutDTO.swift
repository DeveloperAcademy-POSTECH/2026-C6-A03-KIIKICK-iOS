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
struct TrackPointResponse: Decodable {
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
