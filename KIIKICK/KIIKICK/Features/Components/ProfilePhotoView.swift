import SwiftUI

struct ProfilePhotoView: View {
    let url: URL?
    let size: CGFloat
    var preview: Image? = nil

    var body: some View {
        Group {
            if let preview {
                avatar(preview)
            } else if let url, url.scheme?.lowercased() == "https", url.host != nil {
                AsyncImage(url: url) { phase in
                    avatar(phase.image ?? Image("img_profile_default"))
                }
            } else {
                avatar(Image("img_profile_default"))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func avatar(_ image: Image) -> some View {
        image.resizable().scaledToFill()
    }
}
