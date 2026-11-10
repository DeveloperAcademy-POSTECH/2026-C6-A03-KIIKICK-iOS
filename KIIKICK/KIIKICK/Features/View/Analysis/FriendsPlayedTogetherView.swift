//
//  FriendsPlayedTogetherView.swift
//  KIIKICK
//
//  Figma node 371:3852 "withfriend". 서버 QuarterFriendController 계약대로 선택한
//  쿼터 한 개의 친구 목록을 조회하고, 추가·삭제한다. 친구 관계 자체는 변경하지 않는다.

import SwiftUI

struct FriendsPlayedTogetherView: View {
    @Bindable var model: QuarterFriendsModel
    @State private var pushedPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CtaView(
                text: model.isMutating ? "처리 중..." : "친구 추가",
                type: .secondary,
                size: .large,
                icon: Image(systemName: "plus"),
                isActive: model.canMutate
            ) {
                pushedPicker = true
            }

            Text("함께 뛴 친구 \(model.friends.count)")
                .font(.label4SB)
                .foregroundStyle(.gray400)

            if model.isLoading && model.friends.isEmpty {
                ProgressView("친구를 불러오는 중...")
                    .tint(.mint500)
                    .foregroundStyle(.gray300)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else if model.friends.isEmpty {
                EmptyStateView(
                    title: "함께 뛴 친구가 없어요",
                    subtitle: "이 쿼터를 함께 뛴 친구를 추가해 보세요"
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.profiles) { friend in
                            ListWithFriendView(name: friend.nickname) {
                                Task { _ = await model.remove(friendUserID: friend.id) }
                            }
                            .allowsHitTesting(!model.isMutating)
                        }
                    }
                }
            }

            if let errorMessage = model.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.body4R)
                        .foregroundStyle(.red500)
                        .multilineTextAlignment(.center)
                    Button("다시 불러오기") { Task { await model.reload() } }
                        .font(.label4SB)
                        .foregroundStyle(.mint500)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("함께 뛴 친구")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await model.loadIfNeeded() }
        .navigationDestination(isPresented: $pushedPicker) {
            FriendPickerView(excluding: model.friends.map(\.userId)) { friend in
                await model.add(friend)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendsPlayedTogetherView(
            model: QuarterFriendsModel(matchID: UUID(), quarterID: UUID(), provider: MockProvider())
        )
    }
}
