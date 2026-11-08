//
//  NotificationFriendView.swift
//  KIIKICK
//
//  Figma node 317:2053 "notification_friend" (Assets&Components 페이지)
//

import SwiftUI

struct NotificationFriendView: View {
    let nickname: String
    var profileImage: Image? = nil
    var status: FriendRequestStatus = .pending
    var onAccept: () -> Void = {}
    var onReject: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: status == .pending ? 8 : 16) {
            HStack(spacing: 12) {
                (profileImage ?? Image("img_profile_default"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                Text("\(nickname)님이 친구 신청을 보냈어요")
                    .font(.label3M)
                    .foregroundStyle(.gray50)
            }

            switch status {
            case .pending:
                HStack(spacing: 8) {
                    CtaView(text: "수락", type: .primary, size: .small, fillWidth: true, action: onAccept)
                    CtaView(text: "거절", type: .sub, size: .small, fillWidth: true, action: onReject)
                }
            case .accepted:
                Text("친구 신청을 수락했어요")
                    .font(.caption1M)
                    .foregroundStyle(.mint500)
                    .frame(maxWidth: .infinity, alignment: .center)
            case .rejected:
                Text("친구 신청을 거절했어요")
                    .font(.caption1M)
                    .foregroundStyle(.gray400)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        NotificationFriendView(nickname: "닉네임", status: .pending)
        NotificationFriendView(nickname: "닉네임", status: .accepted)
        NotificationFriendView(nickname: "닉네임", status: .rejected)
    }
    .padding()
    .background(Color.gray950)
}
