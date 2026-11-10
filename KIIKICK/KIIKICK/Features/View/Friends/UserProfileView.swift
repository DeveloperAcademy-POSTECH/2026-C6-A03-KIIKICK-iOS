//
//  UserProfileView.swift
//  KIIKICK
//
//  Figma node 575:5845(친구 상태, 경기 기록 추가) / 309:1413(친구 아닌 상태) / 309:1429(친구 요청 보낸 상태)
//  "friend_profile" (iOS 화면), 309:1476 "Alert"(친구 삭제 확인) — 네이티브 iOS Alert(HIG) 컴포넌트
//
//  DESIGN-GAP: 스크롤하면 상단 타이틀이 "프로필"에서 닉네임으로 바뀌는 variant(575:5868)가
//  있지만, 이 앱에 그런 스크롤 연동 타이틀 패턴이 아직 없어 "프로필" 고정으로 구현했다.
//  친구 경기 목록과 분석 결과는 #75의 서버 API로 조회한다.
//
//  이슈 #65: FRIEND-02(GET /users/{userId}/profile)로 들어올 때 상태를 다시 확인하고,
//  FRIEND-05(친구 추가)/FRIEND-08(친구 삭제)을 실제로 호출한다. pendingReceived/blocked는
//  이 화면엔 액션이 없다 — 수락/거절은 알림 탭 몫(이슈 설명 그대로), 차단 해제는 아직
//  연결할 뷰가 없다(이슈 표에 "없음").
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var matches: FriendMatchListModel
    @State private var selectedMatch: FriendMatchAnalysis?
    @State private var status: FriendshipStatus
    @State private var avatarUrl: String?
    @State private var isPresentingRemoveConfirm = false
    @State private var isSubmitting = false
    // 조회 후 기록이 있는 가장 최근 월로 맞춘다.
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var month = Calendar.current.component(.month, from: Date())
    let userId: UUID
    let nickname: String
    var onAddFriend: () -> Void = {}
    var onRemoveFriend: () -> Void = {}

    init(user: UserProfile, onAddFriend: @escaping () -> Void = {}, onRemoveFriend: @escaping () -> Void = {}) {
        _matches = State(initialValue: FriendMatchListModel(userID: user.id))
        self.userId = user.id
        self.nickname = user.nickname
        self._status = State(initialValue: user.status)
        self._avatarUrl = State(initialValue: user.avatarUrl)
        self.onAddFriend = onAddFriend
        self.onRemoveFriend = onRemoveFriend
    }

    private var availableYearMonths: [YearMonth] {
        Array(Set(matches.entries.map {
            let parts = Calendar.current.dateComponents([.year, .month], from: $0.entry.date)
            return YearMonth(year: parts.year ?? year, month: parts.month ?? month)
        }))
    }
    private var entriesInSelectedMonth: [FriendMatchAnalysis] {
        matches.entries.filter {
            let parts = Calendar.current.dateComponents([.year, .month], from: $0.entry.date)
            return parts.year == year && parts.month == month
        }
    }
    private func refreshProfileAndMatches() async {
        await refreshProfile()
        guard !Task.isCancelled else { return }
        if status == .friend { await matches.reload(); syncMonth() } else { matches.clear() }
    }
    private func syncMonth() {
        guard entriesInSelectedMonth.isEmpty, let latest = availableYearMonths.max() else { return }
        year = latest.year
        month = latest.month
    }

    private func refreshProfile() async {
        guard let profile = try? await NetworkService.provider.request(with: FriendEndpoints.profile(userId: userId)) else { return }
        status = FriendshipStatus(relationship: profile.data.relationship)
        avatarUrl = profile.data.avatarUrl
    }

    private func sendFriendRequest() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        guard (try? await NetworkService.provider.request(with: FriendEndpoints.sendFriendRequest(targetUserId: userId))) != nil else { return }
        status = .requestSent
        onAddFriend()
    }

    private func removeFriend() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        guard (try? await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.removeFriend(userId: userId))) != nil else { return }
        onRemoveFriend()
        dismiss()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    profileImage
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    Text(nickname)
                        .font(.head2SB)
                        .foregroundStyle(.gray50)
                }
                .padding(.top, 24)

                switch status {
                case .friend:
                    VStack(alignment: .leading, spacing: 24) {
                        DatePickerView(year: $year, month: $month, availableYearMonths: availableYearMonths)
                        LazyVStack(spacing: 24) {
                            ForEach(entriesInSelectedMonth) { result in
                                let entry = result.entry
                                CardSummaryView(dateAndQuarter: entry.dateAndQuarter, fieldName: entry.fieldName,
                                    stats: entry.stats.map { CardSummaryView.Stat(label: $0.label, value: $0.value, unit: $0.unit) },
                                    action: { selectedMatch = result })
                            }
                            if matches.isLoading { ProgressView() }
                            if matches.entries.isEmpty && !matches.isLoading && matches.errorMessage == nil {
                                EmptyStateView(title: "공개된 경기 기록이 없어요", subtitle: "친구가 분석 보기를 완료하면 기록이 표시돼요")
                            }
                            if let message = matches.errorMessage {
                                Text(message).textStyle(.caption1M).foregroundStyle(.red500)
                                CtaView(text: "다시 시도", type: .secondary, size: .small, isActive: !matches.isLoading) {
                                    Task { await matches.loadMore(); syncMonth() }
                                }
                            } else if matches.hasNext {
                                CtaView(text: "경기 더 보기", type: .sub, size: .small, isActive: !matches.isLoading) {
                                    Task { await matches.loadMore(); syncMonth() }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                case .none:
                    VStack(spacing: 8) {
                        CtaView(text: "친구 추가", type: .primary, size: .large, isActive: !isSubmitting) {
                            Task { await sendFriendRequest() }
                        }
                    }
                    .padding(.top, 48)

                case .requestSent:
                    VStack(spacing: 8) {
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
                    .padding(.top, 48)

                // 이슈 #65: 상대가 먼저 보낸 요청 — 수락/거절은 알림 탭 몫이라 여기엔
                // 안내만 둔다.
                case .pendingReceived:
                    VStack(spacing: 8) {
                        Text("\(nickname)님이 친구 신청을 보냈어요")
                            .font(.caption1M)
                            .foregroundStyle(.mint500)
                        Text("알림 탭에서 수락하거나 거절할 수 있어요")
                            .font(.caption1M)
                            .foregroundStyle(.gray400)
                    }
                    .padding(.top, 48)

                // 이슈 #65: 차단 해제를 연결할 뷰가 아직 없어(표에 "없음") 안내만 둔다.
                case .blocked:
                    Text("차단한 사용자예요")
                        .font(.caption1M)
                        .foregroundStyle(.gray400)
                        .padding(.top, 48)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await refreshProfileAndMatches() }
        .refreshable { await refreshProfileAndMatches() }
        .navigationDestination(item: $selectedMatch) { match in
            FriendMatchDetailView(userID: userId, matchID: match.id, nickname: nickname)
        }
        .toolbar {
            if status == .friend {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("친구 삭제", role: .destructive) {
                            isPresentingRemoveConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .alert("\(nickname)님을 친구에서 삭제할까요?", isPresented: $isPresentingRemoveConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task { await removeFriend() }
            }
        } message: {
            Text("친구 목록에서 사라지며, 다시 친구가 되려면 친구 신청이 필요해요")
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let avatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image("img_profile_default").resizable().aspectRatio(contentMode: .fill)
                }
            }
        } else {
            Image("img_profile_default").resizable().aspectRatio(contentMode: .fill)
        }
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
