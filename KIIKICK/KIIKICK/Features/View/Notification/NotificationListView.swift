//
//  NotificationListView.swift
//  KIIKICK
//
//  Figma node 317:2153 "notification" (이슈 #25로 갱신: 함께 뛴 경기 칩/알림 추가,
//  선택한 칩이 앞으로 오는 정책, 빈 상태 뷰), 317:2362 "Scroll Edge Effect - Soft"
//
//  홈 좌상단 아이콘에서 들어오는 진입점은 홈 UI가 아직 끝나지 않아 이 화면에서는 연결하지 않는다
//  (이슈 #14 작성자 확인 사항).
//

import SwiftUI

struct NotificationListView: View {
    @State private var items: [NotificationItem] = NotificationMockData.items
    @State private var filter: NotificationFilter = .all
    /// 칩이 화면에 그려지는 순서. 기본값은 `전체 - 내 플레이 - 함께 뛴 경기 - 댓글 - 친구`
    /// (= `NotificationFilter.allCases` 선언 순서)이고, 칩을 선택할 때마다 그 칩이 맨 앞으로 온다.
    @State private var chipOrder: [NotificationFilter] = NotificationFilter.allCases
    @State private var pushedAnalysisEntry: AnalysisEntry?

    private var filteredItems: [NotificationItem] {
        filter == .all ? items : items.filter { $0.filterCategory == filter }
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
                        ForEach(chipOrder) { option in
                            Button {
                                select(option)
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
        .navigationDestination(item: $pushedAnalysisEntry) { entry in
            AnalysisDetailView(entry: entry)
        }
    }

    private func select(_ option: NotificationFilter) {
        filter = option
        chipOrder.removeAll { $0 == option }
        chipOrder.insert(option, at: 0)
    }

    @ViewBuilder
    private func notificationRow(for item: NotificationItem) -> some View {
        switch item.kind {
        case .friendRequest(let status, let nickname):
            NotificationFriendView(
                nickname: nickname,
                status: status,
                onAccept: { updateStatus(of: item, to: .accepted) },
                onReject: { updateStatus(of: item, to: .rejected) }
            )
        case .comment(let nickname, let preview):
            NotificationCommentView(nickname: nickname, commentPreview: preview)
        case .withFriend(let nickname, let matchDate):
            NotificationWithFriendView(nickname: nickname, matchDate: matchDate)
        case .myPlay(let matchDate):
            // DESIGN-GAP: Figma annotation대로라면 첫 진입/이후를 나눠서 분석 준비
            // (ReadyForDetailView) vs 분석 결과(AnalysisDetailView)로 갈라야 하는데,
            // ReadyForDetailView/AnalyzingView(이슈 #43)가 이 브랜치엔 없어서 지금은
            // 항상 결과 화면으로 바로 보낸다. 어떤 경기 분석인지 알림 자체엔 식별자가
            // 없어서 목업 중 첫 번째 entry로 고정했다.
            NotificationMyPlayView(matchDate: matchDate) {
                pushedAnalysisEntry = AnalysisMockData.entries.first
            }
        }
    }

    private func updateStatus(of item: NotificationItem, to status: FriendRequestStatus) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              case .friendRequest(_, let nickname) = items[index].kind else { return }
        items[index] = NotificationItem(id: item.id, date: item.date, kind: .friendRequest(status: status, nickname: nickname), isRead: items[index].isRead)
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
}
