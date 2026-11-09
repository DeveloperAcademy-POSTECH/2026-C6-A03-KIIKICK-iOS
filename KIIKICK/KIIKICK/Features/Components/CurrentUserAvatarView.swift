import SwiftUI
import OSLog

/// UserSession에 저장한 URL을 표시한다. 업로드로 URL이 유지돼도 revision 변경 시 다시 로드한다.
struct CurrentUserAvatarView: View {
    @AppStorage(UserSession.avatarUrlKey) private var avatarUrl = ""
    @AppStorage(UserSession.avatarRevisionKey) private var revision = ""
    @State private var image: UIImage?
    @State private var loadedKey: String?
    private static let logger = Logger(subsystem: "KIIKICK", category: "Avatar")

    private var imageKey: String? {
        UserSession.avatarImageCacheKey(url: avatarUrl, revision: revision)
    }

    private var displayedImage: UIImage? {
        guard let key = imageKey else { return nil }
        return UserAvatarImageStore.shared.cachedImage(for: key) ?? (loadedKey == key ? image : nil)
    }

    var body: some View {
        Group {
            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image("img_profile_default")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .task(id: imageKey) {
            guard let key = imageKey else { image = nil; loadedKey = nil; return }
            guard let url = URL(string: avatarUrl),
                  ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return }
            do {
                let loadedImage = try await UserAvatarImageStore.shared.load(url: url, key: key)
                try Task.checkCancellation()
                guard imageKey == key else { return }
                loadedKey = key
                image = loadedImage
            } catch {
                if !Task.isCancelled {
                    Self.logger.error("프로필 이미지 로드 실패. 화면 재진입 시 재시도합니다.")
                }
            }
        }
    }
}
