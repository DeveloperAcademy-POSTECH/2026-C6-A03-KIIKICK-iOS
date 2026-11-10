//
//  FriendPickerView.swift
//  KIIKICK
//
//  함께 뛴 친구로 등록할 대상을 내 친구 전체 페이지에서 고른다.

import SwiftUI

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let excluding: [UUID]
    let onSelect: (UserProfile) async -> Bool

    @State private var friends: [UserProfile] = []
    @State private var isLoading = false
    @State private var selectedFriendID: UUID?
    @State private var errorMessage: String?

    private var selectableFriends: [UserProfile] {
        friends.filter { !excluding.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내 친구 \(selectableFriends.count)")
                .font(.label4SB)
                .foregroundStyle(.gray400)

            if isLoading {
                ProgressView("친구를 불러오는 중...")
                    .tint(.mint500)
                    .foregroundStyle(.gray300)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else if selectableFriends.isEmpty {
                EmptyStateView(
                    title: friends.isEmpty ? "아직 친구가 없어요" : "더 추가할 친구가 없어요",
                    subtitle: friends.isEmpty ? "친구를 추가하면 여기에서 고를 수 있어요" : "이미 모든 친구를 추가했어요"
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(selectableFriends) { friend in
                            Button {
                                Task { await select(friend) }
                            } label: {
                                ListFriendView(name: friend.nickname)
                                    .overlay {
                                        if selectedFriendID == friend.id {
                                            ProgressView().tint(.mint500)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedFriendID != nil)
                        }
                    }
                }
            }

            if let errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.body4R)
                        .foregroundStyle(.red500)
                        .multilineTextAlignment(.center)
                    if friends.isEmpty {
                        Button("다시 불러오기") { Task { await loadFriends() } }
                            .font(.label4SB)
                            .foregroundStyle(.mint500)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("친구 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await loadFriends() }
    }

    private func loadFriends() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var loaded: [UserProfile] = []
            var cursor: String?
            var seenCursors = Set<String>()
            repeat {
                let page = try await NetworkService.provider.request(
                    with: FriendEndpoints.listFriends(cursor: cursor, limit: 100)
                )
                try Task.checkCancellation()
                loaded.append(contentsOf: page.data.map { UserProfile(response: $0.profile) })
                guard page.meta.pagination.hasNext else { break }
                guard let nextCursor = page.meta.pagination.nextCursor,
                      seenCursors.insert(nextCursor).inserted else {
                    throw NetworkError.components
                }
                cursor = nextCursor
            } while true
            var seen = Set<UUID>()
            friends = loaded.filter { seen.insert($0.id).inserted }
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "친구 목록을 불러오지 못했어요. 다시 시도해 주세요"
        }
    }

    private func select(_ friend: UserProfile) async {
        guard selectedFriendID == nil else { return }
        selectedFriendID = friend.id
        errorMessage = nil
        let succeeded = await onSelect(friend)
        selectedFriendID = nil
        if succeeded {
            dismiss()
        } else {
            errorMessage = "친구를 추가하지 못했어요. 다시 시도해 주세요"
        }
    }
}

#Preview {
    NavigationStack {
        FriendPickerView(excluding: []) { _ in true }
    }
}
