import Foundation
import Observation

@MainActor
@Observable
final class NotificationRowModel: Identifiable {
    let id: UUID
    private(set) var item: NotificationItem

    init(item: NotificationItem) {
        id = item.id
        self.item = item
    }

    func updateStatus(to status: FriendRequestStatus) {
        guard case .friendRequest(_, let nickname) = item.kind else { return }
        item = NotificationItem(id: id, date: item.date, kind: .friendRequest(status: status, nickname: nickname))
    }
}
