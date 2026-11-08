import Foundation
import Observation

@MainActor
@Observable
final class NotificationListModel {
    private(set) var sectionsByFilter: [NotificationFilter: [NotificationSection]] = [:]
    @ObservationIgnored private var rowsByID: [UUID: NotificationRowModel] = [:]
    @ObservationIgnored private var loaded = false

    func loadIfNeeded(_ items: [NotificationItem]) {
        guard !loaded else { return }
        replace(items)
    }

    func replace(_ items: [NotificationItem], calendar: Calendar = .current) {
        // 교체 시 인덱스와 섹션을 함께 갱신한다. 같은 ID의 행 모델은 유지한다.
        var nextRows: [UUID: NotificationRowModel] = [:]
        for item in items {
            if let row = rowsByID[item.id], row.item == item {
                nextRows[item.id] = row
            } else {
                nextRows[item.id] = NotificationRowModel(item: item)
            }
        }
        rowsByID = nextRows
        let sorted = nextRows.values.sorted {
            if $0.item.date == $1.item.date { return $0.id.uuidString < $1.id.uuidString }
            return $0.item.date > $1.item.date
        }
        var grouped: [NotificationFilter: [NotificationSection]] = [:]
        for filter in NotificationFilter.allCases {
            let visible = filter == .all ? sorted : sorted.filter { $0.item.filterCategory == filter }
            var sections: [NotificationSection] = []
            var day: Date?
            var rows: [NotificationRowModel] = []
            for row in visible {
                let rowDay = calendar.startOfDay(for: row.item.date)
                if let day, day != rowDay {
                    sections.append(NotificationSection(id: day, rows: rows))
                    rows = []
                }
                day = rowDay
                rows.append(row)
            }
            if let day { sections.append(NotificationSection(id: day, rows: rows)) }
            grouped[filter] = sections
        }
        sectionsByFilter = grouped
        loaded = true
    }

    func sections(for filter: NotificationFilter) -> [NotificationSection] {
        sectionsByFilter[filter] ?? []
    }

    func updateStatus(id: UUID, to status: FriendRequestStatus) {
        // 상태만 바뀌면 날짜·카테고리는 같으므로 해당 행만 갱신하고 재정렬하지 않는다.
        rowsByID[id]?.updateStatus(to: status)
    }

    func regroup(calendar: Calendar = .current) {
        guard loaded else { return }
        replace(rowsByID.values.map(\.item), calendar: calendar)
    }
}
