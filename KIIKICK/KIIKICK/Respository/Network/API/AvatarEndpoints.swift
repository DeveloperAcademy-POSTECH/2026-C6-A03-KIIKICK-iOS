import Foundation

enum AvatarEndpoints {
    static func upload(jpegData: Data) -> Endpoint<Envelope<AvatarResponse>> {
        Endpoint(
            path: "/api/v1/users/me/avatar",
            method: .post,
            multipartBody: MultipartFormData(jpegData: jpegData),
            headers: bearerHeaders()
        )
    }
}

struct AvatarResponse: Decodable {
    let avatarUrl: String
}
