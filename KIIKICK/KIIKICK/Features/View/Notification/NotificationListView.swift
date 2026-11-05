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
    /// 칩이 화면에 그려지는 순서. 기본값은 `전체 - 함께 뛴 경기 - 댓글 - 친구`(= `NotificationFilter.allCases`
    /// 선언 순서)이고, 칩을 선택할 때마다 그 칩이 맨 앞으로 온다.
    @State private var chipOrder: [NotificationFilter] = NotificationFilter.allCases

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
        }
    }

    private func updateStatus(of item: NotificationItem, to status: FriendRequestStatus) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              case .friendRequest(_, let nickname) = items[index].kind else { return }
        items[index] = NotificationItem(id: item.id, date: item.date, kind: .friendRequest(status: status, nickname: nickname))
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
