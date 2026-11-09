//
//  WorkoutPayload.swift
//  KIIKICK Global
//

import CoreLocation
import Foundation

/// 이슈 #66: workout-submissions(완료 경기 일괄 제출)의 WorkoutPayloadCreateRequest.field —
/// Swagger 설명은 "생략/null 허용"이지만 실기기로 확인해보니 실제 서버 검증은 이 필드가
/// 없으면 422로 거부한다. 워치는 아직 운동장 geometry를 모른 채 녹화하므로(iOS가
/// 운동장을 고르면 SessionManager.preparedFieldName으로 "이름"만 보내고, 실제 코너 좌표는
/// 안 보낸다) 워치가 만드는 WorkoutPayload는 계속 이 필드 없이(nil) 보낸다 — iOS가
/// workout-submissions를 호출할 때만 실제 Field로 채운다.
struct WorkoutFieldPayload: Codable {
    struct Corner: Codable {
        let latitude: Double
        let longitude: Double
    }

    let name: String
    let cornerA: Corner
    let cornerB: Corner
    let cornerC: Corner
    let cornerD: Corner
    let rawCornerA: Corner?
    let rawCornerB: Corner?
    let rawCornerC: Corner?
    let rawCornerD: Corner?
}

struct WorkoutPayload: Codable {
    let startDate: Date
    let endDate: Date
    let points: [TrackPoint]
    let heartRateSamples: [HeartRateSample]
    let totalCalories: Double
    let totalDistance: Double
    let events: [MatchEvent]
    var field: WorkoutFieldPayload? = nil
    /// 워치에서 PositionView로 고른 포지션 — 지금까지는 QuarterRecord.position에만
    /// 저장되고 WorkoutPayload에는 안 실려서, iOS로 넘어온 뒤(분석 준비 화면)에는 항상
    /// "선택 필요"로 비어 보였다. 강제 종료된 쿼터는(이슈 #50) 계속 nil.
    var position: Position? = nil
}
