import Foundation

/// 프로필 업로드 API의 file 파트. 파일명은 사용자 입력 대신 고정된 JPEG 이름을 사용한다.
struct MultipartFormData {
    let data: Data
    let contentType: String

    init(jpegData: Data) {
        let boundary = "Boundary-\(UUID().uuidString)"
        contentType = "multipart/form-data; boundary=\(boundary)"
        var body = Data("--\(boundary)\r\n".utf8)
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".utf8))
        body.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        body.append(jpegData)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        data = body
    }
}
