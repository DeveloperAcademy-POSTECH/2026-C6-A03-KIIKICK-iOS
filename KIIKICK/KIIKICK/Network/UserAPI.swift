//
//  UserAPI.swift
//  KIIKICK
//
//  /api/v1/user, /api/v1/user/{userId} (Swagger: User)
//

import Foundation

struct UserCreateRequest: Encodable {
    let nickname: String
}

struct UserUpdateRequest: Encodable {
    let nickname: String
}

struct UserResponse: Decodable {
    let id: UUID
    let nickname: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
}

enum UserAPI {
    static func create(nickname: String) async throws -> UserResponse {
        try await APIClient.send(
            path: "/api/v1/user",
            method: "POST",
            body: UserCreateRequest(nickname: nickname)
        )
    }

    static func get(userId: UUID) async throws -> UserResponse {
        try await APIClient.send(path: "/api/v1/user/\(userId.uuidString)", method: "GET")
    }

    static func update(userId: UUID, nickname: String) async throws -> UserResponse {
        try await APIClient.send(
            path: "/api/v1/user/\(userId.uuidString)",
            method: "PUT",
            body: UserUpdateRequest(nickname: nickname)
        )
    }

    static func delete(userId: UUID) async throws {
        try await APIClient.sendNoContent(path: "/api/v1/user/\(userId.uuidString)", method: "DELETE")
    }
}
