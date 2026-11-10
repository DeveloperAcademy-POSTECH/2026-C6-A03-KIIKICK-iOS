//
//  AddFriendView.swift
//  KIIKICK
//
//  Figma node 309:1448 "addfriend_01"(빈 상태) / 309:1460 "addfriend_02"(검색 결과) — iOS 화면
//
//  DESIGN-GAP: 입력 중(SearchBarView state == .writing) 상태의 목업이 Figma에 따로 없어,
//  빈 값이 아니면 바로 .completed(민트 테두리, 삭제 버튼 없음) 스타일을 적용했다 — 309:1460과 동일.
//
//  이슈 #65: FRIEND-01(GET /users/search)을 연결한다.
//  - 2글자 미만이면 호출하지 않는다("이"/"잇"은 X, "이스"는 O — 이슈에 적힌 기준 그대로
//    String.count로 판단, 조합 중인 자모 하나도 1글자로 센다).
//  - 매 키 입력마다 바로 호출하지 않고, 타이핑이 멈춘 뒤 한 번만 호출한다(디바운싱).
//    `.task(id: query)`가 query 값이 바뀌면 이전 Task를 자동으로 취소해주는 걸 그대로
//    디바운스로 쓴다 — 취소된 Task는 Task.sleep에서 바로 멈춘다.
//

import OSLog
import SwiftUI

struct AddFriendView: View {
    private static let logger = Logger(subsystem: "KIIKICK", category: "FriendSearch")
    private static let minimumQueryLength = 2
    private static let debounceDelay = Duration.milliseconds(400)

    @State private var query: String = ""
    @State private var results: [UserProfile] = []
    @State private var isSearching = false
    @State private var pushedProfile: UserProfile?

    private func search(for query: String) async {
        guard query.count >= Self.minimumQueryLength else {
            results = []
            return
        }
        try? await Task.sleep(for: Self.debounceDelay)
        guard !Task.isCancelled else { return }
        isSearching = true
        defer { isSearching = false }
        // Swagger에 직접 넣어서 비교해볼 수 있게 토큰을 그대로 찍는다 — 디버깅용.
        Self.logger.debug("users/search 호출 중 accessToken: \(UserSession.token ?? "nil", privacy: .public)")
        do {
            let page = try await NetworkService.provider.request(with: FriendEndpoints.searchUsers(query: query))
            guard !Task.isCancelled else { return }
            results = page.data.map { UserProfile(response: $0) }
            Self.logger.debug("users/search(\(query, privacy: .public)) 성공: \(page.data.count)건 — \(page.data.map(\.nickname), privacy: .public)")
        } catch let NetworkError.invalidHttpStatusCode(statusCode, message) {
            Self.logger.debug("users/search(\(query, privacy: .public)) 실패: HTTP \(statusCode, privacy: .public) \(message ?? "", privacy: .public)")
        } catch {
            Self.logger.debug("users/search(\(query, privacy: .public)) 실패: \(String(describing: error), privacy: .public)")
        }
    }

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

                if query.count < Self.minimumQueryLength {
                    Text("닉네임으로 친구를 찾아보세요")
                        .font(.body4R)
                        .foregroundStyle(.gray400)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 48)
                } else if isSearching {
                    ProgressView()
                        .tint(.mint500)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 48)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("검색 결과 \(results.count)")
                            .font(.label4SB)
                            .foregroundStyle(.gray400)

                        if results.isEmpty {
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
                            ForEach(results) { user in
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
        .navigationTitle("친구 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $pushedProfile) { user in
            UserProfileView(user: user)
        }
        .task(id: query) { await search(for: query) }
    }
}

#Preview {
    NavigationStack {
        AddFriendView()
    }
}
