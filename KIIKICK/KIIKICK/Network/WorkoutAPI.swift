//
//  WorkoutAPI.swift
//  KIIKICK
//
//  POST /api/v1/user/{userId}/workout-payloads (Swagger: WorkoutPayload)
//

import Foundation

struct WorkoutPayloadCreateResponse: Decodable {
    let workoutPayloadId: UUID
}

enum WorkoutAPI {
    static func upload(userId: UUID, payload: WorkoutPayload) async throws -> WorkoutPayloadCreateResponse {
        try await APIClient.send(
            path: "/api/v1/user/\(userId.uuidString)/workout-payloads",
            method: "POST",
            body: payload
        )
    }
}
