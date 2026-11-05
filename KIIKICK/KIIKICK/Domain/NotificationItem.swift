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
    /// 상대가 나를 "함께 뛴 친구"로 추가했을 때. `matchDate`는 그 계기가 된 경기 날짜.
    case withFriend(nickname: String, matchDate: Date)
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
        case .withFriend: .withFriend
        }
    }
}

/// `CaseIterable`의 선언 순서가 그대로 칩의 기본 노출 순서다: 전체 - 함께 뛴 경기 - 댓글 - 친구.
enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case withFriend = "함께 뛴 경기"
    case comment = "댓글"
    case friendRequest = "친구"

    var id: String { rawValue }
}
