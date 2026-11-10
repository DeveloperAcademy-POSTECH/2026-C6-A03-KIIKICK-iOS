//
//  UserProfileView.swift
//  KIIKICK
//
//  Figma node 575:5845(친구 상태, 경기 기록 추가) / 309:1413(친구 아닌 상태) / 309:1429(친구 요청 보낸 상태)
//  "friend_profile" (iOS 화면), 309:1476 "Alert"(친구 삭제 확인) — 네이티브 iOS Alert(HIG) 컴포넌트
//
//  DESIGN-GAP: 스크롤하면 상단 타이틀이 "프로필"에서 닉네임으로 바뀌는 variant(575:5868)가
//  있지만, 이 앱에 그런 스크롤 연동 타이틀 패턴이 아직 없어 "프로필" 고정으로 구현했다.
//  "함께 뛴 경기"를 걸러낼 실제 데이터가 없어서(WorkoutRecord는 같이 뛴 사람을 기록하지
//  않는다. 이슈 #26도 뷰 구현만 범위) 항상 빈 목록이다.
//
//  이슈 #65: FRIEND-02(GET /users/{userId}/profile)로 들어올 때 상태를 다시 확인하고,
//  FRIEND-05(친구 추가)/FRIEND-08(친구 삭제)을 실제로 호출한다. pendingReceived/blocked는
//  이 화면엔 액션이 없다 — 수락/거절은 알림 탭 몫(이슈 설명 그대로), 차단 해제는 아직
//  연결할 뷰가 없다(이슈 표에 "없음").
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: FriendshipStatus
    @State private var avatarUrl: String?
    @State private var isPresentingRemoveConfirm = false
    @State private var isSubmitting = false
    // availableYearMonths가 항상 빈 배열이라 DatePickerView가 비활성 상태로 뜬다 —
    // 초깃값은 아무 의미 없어 오늘 날짜로 둔다.
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var month = Calendar.current.component(.month, from: Date())
    let userId: UUID
    let nickname: String
    var onAddFriend: () -> Void = {}
    var onRemoveFriend: () -> Void = {}

    init(user: UserProfile, onAddFriend: @escaping () -> Void = {}, onRemoveFriend: @escaping () -> Void = {}) {
        self.userId = user.id
        self.nickname = user.nickname
        self._status = State(initialValue: user.status)
        self._avatarUrl = State(initialValue: user.avatarUrl)
        self.onAddFriend = onAddFriend
        self.onRemoveFriend = onRemoveFriend
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
                        // 친구와 "함께 뛴 경기"를 식별할 실제 데이터가 없어(WorkoutRecord는
                        // 같이 뛴 사람을 기록하지 않는다) 항상 빈 목록이다.
                        DatePickerView(year: $year, month: $month, availableYearMonths: [])

                        VStack(spacing: 24) {
                            ForEach([AnalysisEntry]()) { entry in
                                CardSummaryView(
                                    dateAndQuarter: entry.dateAndQuarter,
                                    fieldName: entry.fieldName,
                                    stats: entry.stats.map { CardSummaryView.Stat(label: $0.label, value: $0.value, unit: $0.unit) }
                                )
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
        .task { await refreshProfile() }
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
