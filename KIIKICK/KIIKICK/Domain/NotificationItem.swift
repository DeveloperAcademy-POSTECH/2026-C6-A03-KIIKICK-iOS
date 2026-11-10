//
//  NotificationItem.swift
//  KIIKICK
//
//  `FriendRequestStatus`는 Features/Components/NotificationFriendView.swift에 정의되어 있다.
//

import Foundation

enum NotificationKind: Hashable {
    /// `requestId`는 FriendEndpoints.acceptFriendRequest/cancelOrRejectFriendRequest에
    /// 그대로 넘기는 실제 친구 요청 id다(이슈 #65) — GET /friend-requests(RECEIVED)로
    /// 받아온 값을 그대로 들고 다닌다.
    case friendRequest(requestId: UUID, status: FriendRequestStatus, nickname: String)
    case comment(nickname: String, preview: String, matchID: UUID, commentID: UUID? = nil)
    /// 서버에서 받은 알림 중 UI 종류가 확정되지 않은 항목이다. target은 탭 시 재조회할
    /// 대상 힌트로만 쓰며, 실제 권한은 이동한 화면에서 다시 확인한다.
    case remote(title: String, body: String?, target: NotificationTarget)
    /// 상대가 나를 "함께 뛴 친구"로 추가했을 때. `matchDate`는 그 계기가 된 경기 날짜.
    case withFriend(nickname: String, matchDate: Date)
    /// node 747:5385 "notification_myPlay" — 워치에서 경기 분석 결과(WorkoutRecord)가
    /// 도착했을 때(SessionManager.didReceive(file:)). 분석 설정 저장 여부에 따라 준비/상세로 이동한다.
    case myPlay(record: WorkoutRecord)
}

struct NotificationItem: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let kind: NotificationKind
    /// 이슈 #42 "Remind" 댓글 — 알림 아이콘을 안 읽은 알림 유무에 따라 바꾸는 데 쓴다.
    /// 분석/댓글 알림 진입 시 로컬에서 갱신한다. 서버 읽음 상태 동기화·영속화는 별도 작업이다.
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
        case .remote(_, _, let target):
            target.type == "MATCH" ? .myPlay : .all
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
