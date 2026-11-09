import ImageIO
import UIKit

struct AvatarImage {
    let image: UIImage
    let jpegData: Data

    init(data: Data) throws {
        // 원본 전체를 디코딩하지 않고 방향 보정된 썸네일을 만들어 업로드 비용을 제한한다.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw AvatarImageError.invalidImage
        }
        let image = UIImage(cgImage: thumbnail)
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw AvatarImageError.invalidImage
        }
        guard jpegData.count <= 5 * 1024 * 1024 else {
            throw AvatarImageError.tooLarge
        }
        self.image = image
        self.jpegData = jpegData
    }
}

enum AvatarImageError: LocalizedError {
    case invalidImage
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage: "사진을 불러오지 못했어요. 다른 사진을 선택해 주세요"
        case .tooLarge: "프로필 사진은 5 MiB 이하만 업로드할 수 있어요"
        }
    }
}
