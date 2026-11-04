//
//  WorkoutPayloadEndpoints.swift
//  KIIKICK
//

import Foundation

struct WorkoutPayloadCreateResponse: Decodable {
    let workoutPayloadId: UUID
}

enum WorkoutPayloadEndpoints {
    static func upload(userId: UUID, payload: WorkoutPayload) -> Endpoint<WorkoutPayloadCreateResponse> {
        Endpoint(
            path: "/api/v1/user/\(userId.uuidString)/workout-payloads",
            method: .post,
            bodyParameters: payload
        )
    }
}
