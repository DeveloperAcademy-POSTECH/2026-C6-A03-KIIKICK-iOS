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

    init(id: UUID = UUID(), quarterNumber: Int, durationText: String, position: String, heatmapPageCount: Int) {
        self.id = id
        self.quarterNumber = quarterNumber
        self.durationText = durationText
        self.position = position
        self.heatmapPageCount = heatmapPageCount
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
    let dateAndQuarter: String
    let fieldName: String
    let stats: [AnalysisStat]
    let detail: AnalysisDetail

    init(id: UUID = UUID(), dateAndQuarter: String, fieldName: String, stats: [AnalysisStat], detail: AnalysisDetail) {
        self.id = id
        self.dateAndQuarter = dateAndQuarter
        self.fieldName = fieldName
        self.stats = stats
        self.detail = detail
    }
}
