//
//  AnalysisEntry.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" / 367:1711 "detail" (이슈 #17).
//  이슈 #43: AnalysisMockData를 치우고 AnalysisEntry+WorkoutRecord.swift의
//  빌더로 실제 WorkoutRecord(쿼터 하나 = WorkoutRecord 하나)에서 값을 채운다.
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
    /// 워치 PositionView에서 고른 포지션(WorkoutPayload.position → WorkoutRecord.position).
    /// 강제 종료된 쿼터(이슈 #50)는 PositionView를 거치지 못해 계속 nil이다.
    let position: String?
    /// 실제 히트맵을 그릴 수 있는 운동장/경로 — 없으면(운동장 미선택) 히트맵 자리를 비운다.
    let field: Field?
    let points: [TrackPoint]
    /// TimelineView(이슈 #43)용 — 쿼터 동안의 골/어시스트. 위치는 FieldCoordinateMapper로
    /// 실제 GPS 좌표를 정규화한 값, 시각은 쿼터 시작부터의 경과 시간이다.
    let events: [AnalysisMatchEvent]
    /// WorkoutManager.endQuarter가 HealthKit 누적값 차이로 구한 "이번 쿼터 동안"의 실제
    /// 이동거리/소모칼로리 — points에서 다시 합산하는 것보다 정확해서 그대로 들고 다닌다.
    let totalDistanceKm: Double
    let totalCaloriesKcal: Double
    var maxSpeedKmh: Double { (points.map(\.speed).max() ?? 0) * 3.6 }

    init(
        id: UUID = UUID(), quarterNumber: Int, durationText: String, position: String? = nil,
        field: Field? = nil, points: [TrackPoint] = [], events: [AnalysisMatchEvent] = [],
        totalDistanceKm: Double = 0, totalCaloriesKcal: Double = 0
    ) {
        self.id = id
        self.quarterNumber = quarterNumber
        self.durationText = durationText
        self.position = position
        self.field = field
        self.points = points
        self.events = events
        self.totalDistanceKm = totalDistanceKm
        self.totalCaloriesKcal = totalCaloriesKcal
    }

    static func == (lhs: AnalysisQuarter, rhs: AnalysisQuarter) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
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
    /// 이슈 #66: detail.quarters(표시용)와 같은 순서·개수로 대응하는 원본 WorkoutRecord들.
    /// workout-submissions 제출에 필요한 matchId/quarterId/heartRateSamples 등 표시
    /// 모델에는 없는 원본 데이터가 필요해서 들고 다닌다.
    let records: [WorkoutRecord]

    init(
        id: UUID = UUID(), date: Date, dateAndQuarter: String, fieldName: String,
        stats: [AnalysisStat], detail: AnalysisDetail, records: [WorkoutRecord] = []
    ) {
        self.id = id
        self.date = date
        self.dateAndQuarter = dateAndQuarter
        self.fieldName = fieldName
        self.stats = stats
        self.detail = detail
        self.records = records
    }
}

#if DEBUG
/// AnalysisMockData(이슈 #43에서 제거)를 대신하는 Preview 전용 샘플 하나 — 실제
/// WorkoutRecord 빌더(AnalysisEntry+WorkoutRecord.swift)가 채우는 모양을 그대로
/// 손으로 흉내 낸 값이라, 운동장/실제 좌표 없이도 Preview가 뜬다.
extension AnalysisEntry {
    static let previewSample = AnalysisEntry(
        date: DateComponents(calendar: .current, year: 2026, month: 10, day: 28).date!,
        dateAndQuarter: "10월 28일 • 총 2Q",
        fieldName: "우리 집 앞 풋살장",
        stats: [
            AnalysisStat(label: "최고속도", value: "22.6", unit: "km/h"),
            AnalysisStat(label: "이동거리", value: "2.48", unit: "km"),
            AnalysisStat(label: "소모칼로리", value: "245", unit: "kcal"),
        ],
        detail: AnalysisDetail(
            title: "10월 28일",
            quarters: [
                AnalysisQuarter(
                    quarterNumber: 1, durationText: "26:03",
                    events: [
                        AnalysisMatchEvent(type: .goal, timeText: "03:12", position: UnitPoint(x: 0.72, y: 0.72)),
                        AnalysisMatchEvent(type: .assist, timeText: "11:40", position: UnitPoint(x: 0.33, y: 0.42)),
                    ]
                ),
                AnalysisQuarter(quarterNumber: 2, durationText: "24:51"),
            ],
            keyStats: [
                AnalysisStat(label: "최고속도", value: "22.6", unit: "km/h"),
                AnalysisStat(label: "이동거리", value: "2.48", unit: "km"),
                AnalysisStat(label: "소모칼로리", value: "245", unit: "kcal"),
            ],
            goalCount: 1,
            assistCount: 1,
            sections: [
                AnalysisSection(title: "Movement", rows: [
                    AnalysisSectionRow(label: "평균 속력", value: "8.2", unit: "km/h"),
                    AnalysisSectionRow(label: "고강도 주행거리", value: "620", unit: "m"),
                    AnalysisSectionRow(label: "방향 전환 횟수", value: "38", unit: "회"),
                    AnalysisSectionRow(label: "가속 횟수", value: "21", unit: "회"),
                    AnalysisSectionRow(label: "감속 횟수", value: "19", unit: "회"),
                ]),
                AnalysisSection(title: "Physical Activity", rows: [
                    AnalysisSectionRow(label: "최대 심박수", value: "178", unit: "bpm"),
                    AnalysisSectionRow(label: "평균 심박수", value: "142", unit: "bpm"),
                ]),
            ],
            disclaimer: "히트맵과 포지션이 정확한지 확인해주세요"
        )
    )
}
#endif
