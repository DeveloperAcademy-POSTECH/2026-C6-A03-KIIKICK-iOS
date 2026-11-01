//
//  FriendsView.swift
//  KIIKICK
//
//  Figma node 309:1384 "friend" (iOS 화면)
//

import SwiftUI

struct FriendsView: View {
    @State private var friends: [UserProfile] = FriendMockData.myFriends
    @State private var pushedProfile: UserProfile?
    @State private var pushedAddFriend = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("친구")
                    .font(.head1B)
                    .foregroundStyle(.gray50)
                Spacer()
                CtaView(text: "친구 추가", type: .secondary, size: .small, icon: Image(systemName: "plus")) {
                    pushedAddFriend = true
                }
            }
            .padding(.bottom, 4)

            Text("내 친구 \(friends.count)")
                .font(.label4SB)
                .foregroundStyle(.gray400)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(friends) { friend in
                        Button {
                            pushedProfile = friend
                        } label: {
                            ListFriendView(name: friend.nickname)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationBarHidden(true)
        .navigationDestination(item: $pushedProfile) { friend in
            UserProfileView(
                user: friend,
                onRemoveFriend: {
                    friends.removeAll { $0.id == friend.id }
                }
            )
        }
        .navigationDestination(isPresented: $pushedAddFriend) {
            AddFriendView(users: FriendMockData.searchPool)
        }
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
