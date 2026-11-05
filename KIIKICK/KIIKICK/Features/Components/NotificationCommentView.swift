//
//  NotificationCommentView.swift
//  KIIKICK
//
//  Figma node 317:2046 "notification_comment" (Assets&Components 페이지)
//

import SwiftUI

struct NotificationCommentView: View {
    let nickname: String
    let commentPreview: String
    var profileImage: Image? = nil

    var body: some View {
        HStack(spacing: 12) {
            (profileImage ?? Image("img_profile_default"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(nickname)님이 댓글을 달았어요")
                    .font(.label3M)
                    .foregroundStyle(.gray50)
                Text(commentPreview)
                    .font(.body4R)
                    .foregroundStyle(.gray400)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image("ic_arrow")
                .resizable()
                .frame(width: 24, height: 24)
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NotificationCommentView(nickname: "닉네임", commentPreview: "댓글 내용내용내용")
        .padding()
        .background(Color.gray950)
}
