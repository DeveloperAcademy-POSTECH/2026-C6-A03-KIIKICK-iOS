import SwiftUI
import UIKit

/// 서버에서 받은 프로필 이미지 URL을 로컬 캐시와 함께 표시한다.
/// URL이 없거나 다운로드에 실패하면 전달받은 기본 이미지를 사용한다.
struct RemoteAvatarView: View {
    let urlString: String?
    let fallback: Image

    @State private var image: UIImage?

    init(urlString: String?, fallback: Image = Image("img_profile_default")) {
        self.urlString = urlString
        self.fallback = fallback
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                fallback
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .task(id: urlString) {
            image = nil
            guard let url = resolvedURL else {
                return
            }

            do {
                let loadedImage = try await UserAvatarImageStore.shared.load(
                    url: url,
                    key: "remote-avatar|\(url.absoluteString)"
                )
                try Task.checkCancellation()
                image = loadedImage
            } catch {
                // 기본 이미지를 유지한다. 다음 화면 진입 시 다시 시도한다.
            }
        }
    }

    private var resolvedURL: URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        if let url = URL(string: urlString),
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            return url
        }
        return URL(string: urlString, relativeTo: APIConfig.baseURL)?.absoluteURL
    }
}

#Preview {
    RemoteAvatarView(urlString: nil)
        .frame(width: 48, height: 48)
        .clipShape(Circle())
}
