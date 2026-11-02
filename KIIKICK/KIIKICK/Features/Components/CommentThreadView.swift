//
//  CommentThreadView.swift
//  KIIKICK
//
//  Figma node 371:2951 "comment" 안의 comment_thread 컴포넌트(이슈 #17).
//  답글의 L자 커넥터는 실제 SVG 대신 들여쓰기 + 세로선으로 근사했다 — DESIGN-GAP.
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
                    Rectangle()
                        .fill(Color.gray700)
                        .frame(width: 1)
                        .padding(.leading, 20)
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
