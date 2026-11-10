//
//  FriendsView.swift
//  KIIKICK
//
//  Figma node 309:1384 "friend" (iOS 화면)
//
//  이슈 #65: FRIEND-03(GET /friends)을 이 화면 진입 시 호출해 실제 목록을 채운다.
//  커서 기반 페이지네이션은 아직 "더 보기" UI가 없어 첫 페이지만 불러온다 — 친구가
//  아주 많아지면 추가 페이지 로딩이 필요하지만, 지금 범위는 이슈 표에 적힌 목록
//  표시/프로필 연결까지다.
//

import SwiftUI

struct FriendsView: View {
    @State private var friends: [UserProfile] = []
    @State private var pushedProfile: UserProfile?
    @State private var pushedAddFriend = false

    private func loadFriends() async {
        guard let page = try? await NetworkService.provider.request(with: FriendEndpoints.listFriends()) else { return }
        friends = page.data.map { UserProfile(response: $0.profile) }
    }

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
            AddFriendView()
        }
        .task { await loadFriends() }
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
