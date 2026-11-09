import CryptoKit
import UIKit

/// 화면 간 이미지와 진행 중인 다운로드를 공유하고, 재실행 시에는 로컬 썸네일을 사용한다.
@MainActor
final class UserAvatarImageStore {
    static let shared = UserAvatarImageStore()

    private let images = NSCache<NSString, UIImage>()
    private var downloads: [String: Task<UIImage, Error>] = [:]
    private let session: URLSessionable
    private let directory: URL

    init(session: URLSessionable = URLSession.shared, directory: URL? = nil) {
        self.session = session
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProfileAvatar", isDirectory: true)
        images.countLimit = 4
    }

    func cachedImage(for key: String) -> UIImage? {
        images.object(forKey: key as NSString)
    }

    func load(url: URL, key: String) async throws -> UIImage {
        if let image = cachedImage(for: key) { return image }
        if let download = downloads[key] { return try await download.value }

        let download = Task<UIImage, Error> {
            if let data = try? Data(contentsOf: file(for: key)), let image = UIImage(data: data) {
                images.setObject(image, forKey: key as NSString)
                return image
            }
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            try Task.checkCancellation()
            let avatar = try AvatarImage(data: data)
            store(image: avatar.image, data: avatar.jpegData, key: key)
            return avatar.image
        }
        downloads[key] = download
        defer { downloads[key] = nil }
        return try await download.value
    }

    func store(image: UIImage, data: Data, key: String) {
        images.setObject(image, forKey: key as NSString)
        // 캐시 쓰기 실패가 프로필 저장 자체를 실패시키지는 않는다.
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: key), options: .atomic)
    }

    func clear() {
        downloads.values.forEach { $0.cancel() }
        downloads.removeAll()
        images.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
    }

    private func file(for key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(hash).appendingPathExtension("jpg")
    }
}
