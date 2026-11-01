//
//  UserProfileView.swift
//  KIIKICK
//
//  Figma node 309:1397(친구 상태) / 309:1413(친구 아닌 상태) / 309:1429(친구 요청 보낸 상태)
//  "friend_profile" (iOS 화면)
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: FriendshipStatus
    let nickname: String
    var onAddFriend: () -> Void = {}
    var onRemoveFriend: () -> Void = {}

    init(user: UserProfile, onAddFriend: @escaping () -> Void = {}, onRemoveFriend: @escaping () -> Void = {}) {
        self.nickname = user.nickname
        self._status = State(initialValue: user.status)
        self.onAddFriend = onAddFriend
        self.onRemoveFriend = onRemoveFriend
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 36) {
                ProfileAvatarView()
                Text(nickname)
                    .font(.head2SB)
                    .foregroundStyle(.gray50)
            }
            .padding(.top, 52)

            VStack(spacing: 8) {
                switch status {
                case .friend:
                    CtaView(text: "친구 삭제", type: .destructive, size: .large) {
                        onRemoveFriend()
                        dismiss()
                    }
                case .none:
                    CtaView(text: "친구 추가", type: .primary, size: .large) {
                        status = .requestSent
                        onAddFriend()
                    }
                case .requestSent:
                    CtaView(text: "신청 완료", type: .primary, size: .large, isActive: false) {}
                    VStack(spacing: 8) {
                        Text("친구 신청을 보냈어요")
                            .font(.caption1M)
                            .foregroundStyle(.mint500)
                        Text("상대가 수락하면 친구 목록에 표시돼요")
                            .font(.caption1M)
                            .foregroundStyle(.gray400)
                    }
                }
            }
            .padding(.top, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color.gray950)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "갱아", status: .friend))
    }
}

#Preview("친구 아님") {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "조승연", status: .none))
    }
}

#Preview("요청 보냄") {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "조승연", status: .requestSent))
    }
}
