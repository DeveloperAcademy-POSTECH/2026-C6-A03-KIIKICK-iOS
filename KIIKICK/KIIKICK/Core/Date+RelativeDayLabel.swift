//
//  Date+RelativeDayLabel.swift
//  KIIKICK
//
//  이슈 #14 ToDo: 알림 목록 섹션 날짜 형식 — 오늘, 어제, 2일 전 ~ 7일 전, 그 이전은 yyyy.MM.dd.
//

import Foundation

extension Date {
    func relativeDayLabel(calendar: Calendar = .current, now: Date = Date()) -> String {
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfToday = calendar.startOfDay(for: now)
        let daysAgo = calendar.dateComponents([.day], from: startOfSelf, to: startOfToday).day ?? 0
        
        switch daysAgo {
        case 0: return "오늘"
        case 1: return "어제"
        case 2...7: return "\(daysAgo)일 전"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: self)
        }
    }
}
