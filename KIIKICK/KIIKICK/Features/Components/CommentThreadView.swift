//
//  CommentThreadView.swift
//  KIIKICK
//
//  Figma node 371:2951 "comment" 안의 comment_thread 컴포넌트(이슈 #17).
//  답글 커넥터는 node 742:12867의 reply_connector SVG(ic_reply_connector)를 그대로 쓴다.
//

import SwiftUI

struct CommentThreadView: View {
    let comment: Comment
    var onReply: (Comment) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(
                avatarImageName: comment.avatarImageName,
                nickname: comment.authorNickname,
                content: comment.content,
                timestamp: comment.timestamp
            )

            Button {
                onReply(comment)
            } label: {
                Text("답글 달기")
                    .font(.label3M)
                    .foregroundStyle(.gray400)
            }
            .buttonStyle(.plain)
            .padding(.leading, 52)

            ForEach(comment.replies) { reply in
                HStack(alignment: .top, spacing: 8) {
                    Image("ic_reply_connector")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 12, height: 20)
                        .foregroundStyle(.gray700)
                    row(
                        avatarImageName: reply.avatarImageName,
                        nickname: reply.authorNickname,
                        content: reply.content,
                        timestamp: reply.timestamp
                    )
                }
                .padding(.leading, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(avatarImageName: String?, nickname: String, content: String, timestamp: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            (avatarImageName.map { Image($0) } ?? Image("img_profile_default"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(nickname)
                        .font(.title4SB)
                        .foregroundStyle(.gray50)
                    Text(timestamp)
                        .font(.caption1M)
                        .foregroundStyle(.gray500)
                }
                Text(content)
                    .font(.body4R)
                    .foregroundStyle(.gray50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(CommentMockData.threads) { CommentThreadView(comment: $0) }
        }
        .padding()
    }
    .background(Color.gray950)
}
