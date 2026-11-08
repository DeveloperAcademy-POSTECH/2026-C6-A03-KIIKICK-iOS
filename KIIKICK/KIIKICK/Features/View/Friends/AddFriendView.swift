//
//  AddFriendView.swift
//  KIIKICK
//
//  Figma node 309:1448 "addfriend_01"(빈 상태) / 309:1460 "addfriend_02"(검색 결과) — iOS 화면
//
//  DESIGN-GAP: 입력 중(SearchBarView state == .writing) 상태의 목업이 Figma에 따로 없어,
//  빈 값이 아니면 바로 .completed(민트 테두리, 삭제 버튼 없음) 스타일을 적용했다 — 309:1460과 동일.
//

import SwiftUI

struct AddFriendView: View {
    @State private var query: String = ""
    @State private var pushedProfile: UserProfile?
    let users: [UserProfile]

    @State private var searchModel = FriendSearchModel()

    var body: some View {
        // dismissKeyboardOnTap()을 검색 결과 ForEach(매 입력마다 행 개수가 바뀜)와 같은 VStack에
        // 바로 걸면, 탭 제스처가 달린 view의 하위 트리가 매 키 입력마다 구조적으로 바뀌면서
        // 제스처가 다시 붙는 타이밍에 포커스가 끊겨 키보드가 내려갔다. 제스처를 입력/결과와
        // 무관하게 항상 같은 크기인 배경 레이어로 분리해 이 결합을 끊는다.
        ZStack(alignment: .top) {
            Color.gray950
                .ignoresSafeArea()
                .dismissKeyboardOnTap()

            VStack(alignment: .leading, spacing: 24) {
                SearchBarView(
                    text: $query,
                    placeholder: "여기에 입력하세요",
                    state: query.isEmpty ? .default : .completed,
                    onClear: { query = "" }
                )

                if query.isEmpty {
                    Text("닉네임으로 친구를 찾아보세요")
                        .font(.body4R)
                        .foregroundStyle(.gray400)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 48)
                } else {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text("검색 결과 \(searchModel.results.count)")
                            .font(.label4SB)
                            .foregroundStyle(.gray400)

                        if searchModel.isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if searchModel.results.isEmpty {
                            VStack(spacing: 16) {
                                Text("검색 결과가 없어요")
                                    .font(.title4SB)
                                    .foregroundStyle(.gray50)
                                Text("닉네임을 확인하고 다시 검색해 보세요")
                                    .font(.body4R)
                                    .foregroundStyle(.gray50)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(searchModel.results) { user in
                                Button {
                                    pushedProfile = user
                                } label: {
                                    ListFriendView(name: user.nickname, isWaiting: user.status == .requestSent)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task(id: FriendSearchRequest(query: query, users: users)) {
            await searchModel.search(FriendSearchRequest(query: query, users: users))
        }
        .onChange(of: query) { _, _ in
            searchModel.prepare(for: query)
        }
        .onChange(of: users) { _, _ in
            searchModel.prepare(for: query)
        }
        .navigationTitle("친구 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $pushedProfile) { user in
            UserProfileView(user: user)
        }
    }
}

#Preview {
    NavigationStack {
        AddFriendView(users: FriendMockData.searchPool)
    }
}
