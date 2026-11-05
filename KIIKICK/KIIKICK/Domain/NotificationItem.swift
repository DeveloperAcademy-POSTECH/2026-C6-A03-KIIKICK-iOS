//
//  NotificationItem.swift
//  KIIKICK
//
//  `FriendRequestStatus`는 Features/Components/NotificationFriendView.swift에 정의되어 있다.
//

import Foundation

enum NotificationKind: Hashable {
    case friendRequest(status: FriendRequestStatus, nickname: String)
    case comment(nickname: String, preview: String)
}

struct NotificationItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let kind: NotificationKind
    
    init(id: UUID = UUID(), date: Date, kind: NotificationKind) {
        self.id = id
        self.date = date
        self.kind = kind
    }
    
    var filterCategory: NotificationFilter {
        switch kind {
        case .friendRequest: .friendRequest
        case .comment: .comment
        }
    }
}

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case comment = "댓글"
    case friendRequest = "친구 신청"

    var id: String { rawValue }
}
