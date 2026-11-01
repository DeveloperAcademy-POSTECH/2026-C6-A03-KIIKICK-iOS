//
//  NotificationListView.swift
//  KIIKICK
//
//  Figma node 317:2153 "notification" (iOS 화면)
//
//  DESIGN-GAP: 칩("전체"/"댓글"/"친구 신청")으로 목록을 거르는 동작 자체는 Figma 스크린샷에
//  필터링된 상태가 없어, 칩 종류와 NotificationKind를 1:1로 매칭해 거르는 것으로 추정 구현했다.
//
//  홈 좌상단 아이콘에서 들어오는 진입점은 홈 UI가 아직 끝나지 않아 이 화면에서는 연결하지 않는다
//  (이슈 #14 작성자 확인 사항).
//

import SwiftUI

struct NotificationListView: View {
    @State private var items: [NotificationItem] = NotificationMockData.items
    @State private var filter: NotificationFilter = .all

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
                    ForEach(NotificationFilter.allCases) { option in
                        Button {
                            filter = option
                        } label: {
                            FilterChipView(text: option.rawValue, isSelected: filter == option)
                        }
                        .buttonStyle(.plain)
                    }
                }

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
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
        }
    }

    private func updateStatus(of item: NotificationItem, to status: FriendRequestStatus) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              case .friendRequest(_, let nickname) = items[index].kind else { return }
        items[index] = NotificationItem(id: item.id, date: item.date, kind: .friendRequest(status: status, nickname: nickname))
    }
}

#Preview {
    NavigationStack {
        NotificationListView()
    }
}
