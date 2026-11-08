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
    /// node 747:5385 "notification_myPlay" — 경기 분석 결과가 준비됐을 때. `matchDate`는
    /// 그 경기 날짜("10월 30일 경기 분석 결과가 도착했어요!" 문구에 쓰인다).
    case myPlay(matchDate: Date)
}

struct NotificationItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let kind: NotificationKind
    /// 이슈 #42 "Remind" 댓글 — 알림 아이콘을 안 읽은 알림 유무에 따라 바꾸는 데 쓴다.
    /// DESIGN-GAP: 서버/로컬 저장소가 없어서 "읽음 처리" 자체가 아직 없다 — 지금은
    /// NotificationMockData의 고정값일 뿐, NotificationListView에서 읽어도 안 바뀐다.
    var isRead: Bool

    init(id: UUID = UUID(), date: Date, kind: NotificationKind, isRead: Bool = false) {
        self.id = id
        self.date = date
        self.kind = kind
        self.isRead = isRead
    }

    var filterCategory: NotificationFilter {
        switch kind {
        case .friendRequest: .friendRequest
        case .comment: .comment
        case .withFriend: .withFriend
        case .myPlay: .myPlay
        }
    }
}

/// `CaseIterable`의 선언 순서가 그대로 칩의 기본 노출 순서다: 전체 - 내 플레이 - 함께 뛴 경기 - 댓글 - 친구.
enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case myPlay = "내 플레이"
    case withFriend = "함께 뛴 경기"
    case comment = "댓글"
    case friendRequest = "친구"

    var id: String { rawValue }
}
