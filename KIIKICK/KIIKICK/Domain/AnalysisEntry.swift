//
//  AnalysisEntry.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" / 367:1711 "detail" (이슈 #17, 목업 데이터 전용 모델).
//  WorkoutRecord/SwiftData와는 완전히 분리돼 있다 — 실제 데이터 연동은 이 이슈 범위 밖.
//

import Foundation

struct AnalysisStat: Hashable {
    let label: String
    let value: String
    let unit: String
}

struct AnalysisQuarter: Identifiable, Hashable {
    let id: UUID
    let quarterNumber: Int
    let durationText: String
    let position: String
    /// 실제 히트맵 이미지가 아직 없어서 캐러셀 페이지 수만 갖고 있다 — DESIGN-GAP.
    let heatmapPageCount: Int
    /// TimelineView(이슈 #43)용 — 쿼터별 골/어시스트 개수. 실제 타임스탬프 데이터가
    /// 없어 목록은 전부 "00:00"으로 보여준다(Figma 목업 자체도 00:00 고정값).
    let goalCount: Int
    let assistCount: Int

    init(
        id: UUID = UUID(), quarterNumber: Int, durationText: String, position: String,
        heatmapPageCount: Int, goalCount: Int = 0, assistCount: Int = 0
    ) {
        self.id = id
        self.quarterNumber = quarterNumber
        self.durationText = durationText
        self.position = position
        self.heatmapPageCount = heatmapPageCount
        self.goalCount = goalCount
        self.assistCount = assistCount
    }
}

struct AnalysisSectionRow: Hashable {
    let label: String
    let value: String
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
