//
//  UserEndpoints.swift
//  KIIKICK
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

enum UserEndpoints {
    static func create(nickname: String) -> Endpoint<UserResponse> {
        Endpoint(path: "/api/v1/user", method: .post, bodyParameters: UserCreateRequest(nickname: nickname))
    }
    
    static func get(userId: UUID) -> Endpoint<UserResponse> {
        Endpoint(path: "/api/v1/user/\(userId.uuidString)", method: .get)
    }
    
    static func update(userId: UUID, nickname: String) -> Endpoint<UserResponse> {
        Endpoint(
            path: "/api/v1/user/\(userId.uuidString)",
            method: .put,
            bodyParameters: UserUpdateRequest(nickname: nickname)
        )
    }
    
    static func delete(userId: UUID) -> Endpoint<Void> {
        Endpoint(path: "/api/v1/user/\(userId.uuidString)", method: .delete)
    }
}
