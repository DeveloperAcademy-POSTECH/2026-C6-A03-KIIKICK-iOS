import ImageIO
import PhotosUI
import SwiftUI

struct ProfilePhoto {
    let image: UIImage
    let jpeg: Data

    static func load(_ item: PhotosPickerItem) async throws -> Self {
        guard let data = try await item.loadTransferable(type: Data.self),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 512
              ] as CFDictionary) else {
            throw InvalidImage()
        }

        let image = UIImage(cgImage: thumbnail)
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw InvalidImage()
        }
        return Self(image: image, jpeg: jpeg)
    }

    struct InvalidImage: Error {}
}
