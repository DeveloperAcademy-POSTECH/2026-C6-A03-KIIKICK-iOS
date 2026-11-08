//
//  AnalysisEntry.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" / 367:1711 "detail" (이슈 #17, 목업 데이터 전용 모델).
//  WorkoutRecord/SwiftData와는 완전히 분리돼 있다 — 실제 데이터 연동은 이 이슈 범위 밖.
//

import Foundation
import SwiftUI

struct AnalysisStat: Hashable {
    let label: String
    let value: String
    let unit: String
}

enum TimelineEventType {
    case goal, assist

    var iconName: String { self == .goal ? "ic_goal" : "ic_assist" }
    var label: String { self == .goal ? "Goal" : "Assist" }
}

/// TimelineView(이슈 #43)의 지도 위에 찍을 골/어시스트 한 건. `position`은 지도 뷰 안에서의
/// 상대 좌표(0...1, 왼쪽위가 원점)다 — 실제 위치 변환 로직이 없어 목업 좌표를 그대로 쓴다.
struct AnalysisMatchEvent: Identifiable, Hashable {
    let id: UUID
    let type: TimelineEventType
    let timeText: String
    let position: UnitPoint

    init(id: UUID = UUID(), type: TimelineEventType, timeText: String, position: UnitPoint) {
        self.id = id
        self.type = type
        self.timeText = timeText
        self.position = position
    }
}

struct AnalysisQuarter: Identifiable, Hashable {
    let id: UUID
    let quarterNumber: Int
    let durationText: String
    let position: String
    /// 실제 히트맵 이미지가 아직 없어서 캐러셀 페이지 수만 갖고 있다 — DESIGN-GAP.
    let heatmapPageCount: Int
    /// TimelineView(이슈 #43)용 — 쿼터 동안의 골/어시스트. 실제 타임스탬프/위치 데이터가
    /// 없어 목록은 전부 "00:00"과 목업 좌표로 보여준다(Figma 목업 자체도 00:00 고정값).
    let events: [AnalysisMatchEvent]

    init(
        id: UUID = UUID(), quarterNumber: Int, durationText: String, position: String,
        heatmapPageCount: Int, events: [AnalysisMatchEvent] = []
    ) {
        self.id = id
        self.quarterNumber = quarterNumber
        self.durationText = durationText
        self.position = position
        self.heatmapPageCount = heatmapPageCount
        self.events = events
    }
}

/// node 735:11440 등 — 값(value)과 단위(unit)는 Figma에서부터 서로 다른 Text로
/// 분리돼 있고 색도 다르다(값은 color-text-primary, 단위는 color-text-secondary
/// 라서 문자열 하나로 합쳐두면 색을 나눠 칠할 수 없다.
struct AnalysisSectionRow: Hashable {
    let label: String
    let value: String
    let unit: String
}

struct AnalysisSection: Identifiable, Hashable {
    let id: UUID
    let title: String
    let rows: [AnalysisSectionRow]

    init(id: UUID = UUID(), title: String, rows: [AnalysisSectionRow]) {
        self.id = id
        self.title = title
        self.rows = rows
    }
}

struct AnalysisDetail: Identifiable, Hashable {
    let id: UUID
    let title: String
    let quarters: [AnalysisQuarter]
    let keyStats: [AnalysisStat]
    let goalCount: Int
    let assistCount: Int
    let sections: [AnalysisSection]
    let disclaimer: String

    init(
        id: UUID = UUID(),
        title: String,
        quarters: [AnalysisQuarter],
        keyStats: [AnalysisStat],
        goalCount: Int,
        assistCount: Int,
        sections: [AnalysisSection],
        disclaimer: String
    ) {
        self.id = id
        self.title = title
        self.quarters = quarters
        self.keyStats = keyStats
        self.goalCount = goalCount
        self.assistCount = assistCount
        self.sections = sections
        self.disclaimer = disclaimer
    }
}

struct AnalysisEntry: Identifiable, Hashable {
    let id: UUID
    /// 이슈 #43: 날짜 선택 컴포넌트가 "기록이 있는 연도/월만" 고를 수 있게 하려고
    /// 추가했다 — dateAndQuarter는 표시용 문자열이라 거꾸로 파싱하지 않는다.
    let date: Date
    let dateAndQuarter: String
    let fieldName: String
    let stats: [AnalysisStat]
    let detail: AnalysisDetail

    init(id: UUID = UUID(), date: Date, dateAndQuarter: String, fieldName: String, stats: [AnalysisStat], detail: AnalysisDetail) {
        self.id = id
        self.date = date
        self.dateAndQuarter = dateAndQuarter
        self.fieldName = fieldName
        self.stats = stats
        self.detail = detail
    }
}
