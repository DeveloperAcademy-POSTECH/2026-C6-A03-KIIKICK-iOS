//
//  FriendsPlayedTogetherView.swift
//  KIIKICK
//
//  Figma node 371:3852 "withfriend" (이슈 #17). 댓글 세그먼트 안의 "함께 뛴 친구" 행에서만
//  진입한다 — 분석탭 리스트에는 진입 지점이 없다(이슈 본문에 명시).
//

import SwiftUI

struct FriendsPlayedTogetherView: View {
    @State private var friends: [UserProfile]
    @State private var pushedAddFriend = false

    init(friends: [UserProfile]) {
        self._friends = State(initialValue: friends)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CtaView(text: "친구 추가", type: .secondary, size: .large, icon: Image(systemName: "plus")) {
                pushedAddFriend = true
            }

            Text("함께 뛴 친구 \(friends.count)")
                .font(.label4SB)
                .foregroundStyle(.gray400)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(friends) { friend in
                        ListWithFriendView(name: friend.nickname) {
                            friends.removeAll { $0.id == friend.id }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("함께 뛴 친구")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $pushedAddFriend) {
            AddFriendView(users: [])
        }
    }
}

#Preview {
    NavigationStack {
        FriendsPlayedTogetherView(friends: [])
    }
}
