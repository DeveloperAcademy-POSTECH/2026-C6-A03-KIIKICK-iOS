//
//  NotificationListView.swift
//  KIIKICK
//
//  Figma node 317:2153 "notification" (이슈 #25로 갱신: 함께 뛴 경기 칩/알림 추가,
//  빈 상태 뷰), 317:2362 "Scroll Edge Effect - Soft"
//
//  홈 좌상단 아이콘에서 들어오는 진입점은 홈 UI가 아직 끝나지 않아 이 화면에서는 연결하지 않는다
//  (이슈 #14 작성자 확인 사항).
//
//  목록 자체는 로컬 @State가 아니라 SessionManager.notifications(공용 저장소)를 그대로
//  쓴다 — 경기 분석 결과가 도착하면(SessionManager.didReceive(file:)) 홈 화면 벨 아이콘과
//  이 목록이 같은 데이터를 보고 즉시 같이 반영돼야 하기 때문이다.
//

import SwiftUI

struct NotificationListView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var filter: NotificationFilter = .all
    @State private var pushedRecord: WorkoutRecord?

    private var filteredItems: [NotificationItem] {
        filter == .all ? sessionManager.notifications : sessionManager.notifications.filter { $0.filterCategory == filter }
    }

    private var groupedSections: [(label: String, items: [NotificationItem])] {
        let calendar = Calendar.current
        let sorted = filteredItems.sorted { $0.date > $1.date }
        let groupedByDay = Dictionary(grouping: sorted) { calendar.startOfDay(for: $0.date) }
        return groupedByDay.keys.sorted(by: >).map { day in
            (label: day.relativeDayLabel(), items: groupedByDay[day] ?? [])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // node 317:2506 "chips" 프레임 자체가 437pt로 화면 폭(402pt)보다 넓다 —
                // 칩이 5개(전체/내 플레이/함께 뛴 경기/댓글/친구)가 되면서 한 줄에 다 못
                // 들어가고, 가로 스크롤로 보게 돼 있다. 이걸 그냥 HStack으로만 두면 칩
                // 텍스트가 줄바꿈되며 찌그러진다 — 가로 ScrollView로 감쌌다.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NotificationFilter.allCases) { option in
                            Button {
                                filter = option
                            } label: {
                                FilterChipView(text: option.rawValue, isSelected: filter == option)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if groupedSections.isEmpty {
                    EmptyStateView(
                        title: "아직 알림이 없어요",
                        subtitle: "친구들과의 활동이 생기면 이곳에서 알려드려요"
                    )
                    .padding(.top, 48)
                } else {
                    ForEach(groupedSections, id: \.label) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.label)
                                .font(.label4SB)
                                .foregroundStyle(.gray400)

                            ForEach(section.items) { item in
                                notificationRow(for: item)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .applyingSoftTopScrollEdgeEffect()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $pushedRecord) { record in
            WorkoutDetailView(record: record)
                .toolbar(.hidden, for: .tabBar)
        }
        // 이슈 #65: GET /friend-requests(RECEIVED)로 받은 대기 중인 친구 요청을
        // sessionManager.notifications에 합친다 — 알림 목록은 이 저장소 하나를 그대로
        // 보여주므로, 수락/거절 버튼이 실제 requestId를 들고 있게 하려면 여기서
        // 채워 넣어야 한다. 이미 들어있는 요청(같은 requestId)은 중복 추가하지 않는다.
        .task { await syncPendingFriendRequests() }
    }

    private func syncPendingFriendRequests() async {
        let existingRequestIds: Set<UUID> = Set(sessionManager.notifications.compactMap {
            if case .friendRequest(let requestId, _, _) = $0.kind { return requestId }
            return nil
        })
        do {
            let page = try await NetworkService.provider.request(
                with: FriendEndpoints.listFriendRequests(direction: .received)
            )
            let newRequests = page.data.filter { $0.status == .pending && !existingRequestIds.contains($0.id) }
            for request in newRequests {
                // Request에는 닉네임이 없어서 요청자 프로필을 따로 조회한다.
                guard let profile = try? await NetworkService.provider.request(
                    with: FriendEndpoints.profile(userId: request.requesterId)
                ) else { continue }
                sessionManager.notifications.insert(
                    NotificationItem(
                        date: request.createdAt,
                        kind: .friendRequest(requestId: request.id, status: .pending, nickname: profile.data.nickname)
                    ),
                    at: 0
                )
            }
        } catch {
            // 목록을 못 받아와도 기존 알림(myPlay 등)은 그대로 보여준다.
        }
    }

    @ViewBuilder
    private func notificationRow(for item: NotificationItem) -> some View {
        switch item.kind {
        case .friendRequest(let requestId, let status, let nickname):
            NotificationFriendView(
                nickname: nickname,
                status: status,
                onAccept: { Task { await respondToFriendRequest(item: item, requestId: requestId, accept: true) } },
                onReject: { Task { await respondToFriendRequest(item: item, requestId: requestId, accept: false) } }
            )
        case .comment(let nickname, let preview):
            NotificationCommentView(nickname: nickname, commentPreview: preview)
        case .withFriend(let nickname, let matchDate):
            NotificationWithFriendView(nickname: nickname, matchDate: matchDate)
        case .myPlay(let record):
            // DESIGN-GAP: Figma annotation대로라면 첫 진입/이후를 나눠서 분석 준비
            // (ReadyForDetailView) vs 분석 결과(WorkoutDetailView)로 갈라야 하는데,
            // ReadyForDetailView/AnalyzingView(이슈 #43)가 이 브랜치엔 없어서 지금은
            // 항상 결과 화면으로 바로 보낸다.
            NotificationMyPlayView(matchDate: record.date) {
                pushedRecord = record
            }
        }
    }

    /// 이슈 #65: FRIEND-06(수락)/FRIEND-07(거절)을 실제로 호출한다. 성공해야만 뱃지를
    /// 바꾼다 — 실패하면 버튼이 그대로 남아 다시 누를 수 있다.
    private func respondToFriendRequest(item: NotificationItem, requestId: UUID, accept: Bool) async {
        do {
            if accept {
                _ = try await NetworkService.provider.request(with: FriendEndpoints.acceptFriendRequest(requestId: requestId))
            } else {
                try await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.cancelOrRejectFriendRequest(requestId: requestId))
            }
            updateStatus(of: item, to: accept ? .accepted : .rejected)
        } catch {
            // 실패하면 버튼을 그대로 둬서 다시 시도할 수 있게 한다.
        }
    }

    private func updateStatus(of item: NotificationItem, to status: FriendRequestStatus) {
        guard let index = sessionManager.notifications.firstIndex(where: { $0.id == item.id }),
              case .friendRequest(let requestId, _, let nickname) = sessionManager.notifications[index].kind else { return }
        sessionManager.notifications[index] = NotificationItem(
            id: item.id, date: item.date, kind: .friendRequest(requestId: requestId, status: status, nickname: nickname),
            isRead: sessionManager.notifications[index].isRead
        )
    }
}

private extension View {
    /// `scrollEdgeEffectStyle`는 iOS 26부터 있는데 프로젝트 배포 타깃은 18.6이라 가드한다.
    @ViewBuilder
    func applyingSoftTopScrollEdgeEffect() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        NotificationListView()
    }
    .environment(SessionManager.shared)
}
