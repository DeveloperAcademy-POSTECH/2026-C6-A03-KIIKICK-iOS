import Foundation

struct ProfileEnvelope<T: Decodable>: Decodable {
    let data: T
}

struct ProfileAvatar: Decodable {
    let avatarUrl: URL?
}

enum ProfileEndpoints {
    private static let path = "/api/v1/users/me"

    static func get(token: String) -> Endpoint<ProfileEnvelope<ProfileAvatar>> {
        Endpoint(path: path, headers: authorization(token))
    }

    static func updateNickname(_ nickname: String, token: String) -> Endpoint<ProfileEnvelope<ProfileAvatar>> {
        Endpoint(
            path: path,
            method: .patch,
            bodyParameters: UserUpdateRequest(nickname: nickname),
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json",
                "Idempotency-Key": UUID().uuidString
            ]
        )
    }

    static func uploadAvatar(_ jpeg: Data, token: String) -> Endpoint<ProfileEnvelope<ProfileAvatar>> {
        let boundary = UUID().uuidString
        var body = Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        body.append(jpeg)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return Endpoint(
            path: "\(path)/avatar",
            method: .post,
            bodyData: body,
            headers: [
                "Authorization": "Bearer \(token)",
                "Content-Type": "multipart/form-data; boundary=\(boundary)"
            ]
        )
    }

    static func removeAvatar(token: String) -> Endpoint<Void> {
        Endpoint(path: "\(path)/avatar", method: .delete, headers: authorization(token))
    }

    private static func authorization(_ token: String) -> [String: String] {
        ["Authorization": "Bearer \(token)"]
    }
}
