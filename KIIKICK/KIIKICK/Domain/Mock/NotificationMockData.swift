//
//  NotificationMockData.swift
//  KIIKICK
//
//  오늘/어제/N일 전/날짜 형식 구간을 모두 확인할 수 있도록 날짜를 분산시켜 둔다.
//

import Foundation

enum NotificationMockData {
    static let items: [NotificationItem] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func date(daysAgo: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        return [
            NotificationItem(date: date(daysAgo: 0, hour: 9), kind: .friendRequest(status: .pending, nickname: "갱아")),
            NotificationItem(date: date(daysAgo: 0, hour: 11), kind: .friendRequest(status: .accepted, nickname: "루디")),
            NotificationItem(date: date(daysAgo: 0, hour: 14), kind: .comment(nickname: "곤", preview: "댓글 내용내용내용")),
            NotificationItem(date: date(daysAgo: 0, hour: 16), kind: .withFriend(nickname: "애셔", matchDate: date(daysAgo: 0, hour: 0))),
            NotificationItem(date: date(daysAgo: 1, hour: 10), kind: .friendRequest(status: .rejected, nickname: "애셔")),
            NotificationItem(date: date(daysAgo: 1, hour: 18), kind: .comment(nickname: "조승연", preview: "오늘 경기 어땠어?")),
            NotificationItem(date: date(daysAgo: 3, hour: 9), kind: .friendRequest(status: .pending, nickname: "조승연아")),
            NotificationItem(date: date(daysAgo: 10, hour: 9), kind: .comment(nickname: "조승연이", preview: "다음에 또 보자")),
        ]
    }()
}
