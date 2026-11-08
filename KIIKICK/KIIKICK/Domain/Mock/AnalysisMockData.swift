//
//  AnalysisMockData.swift
//  KIIKICK
//
//  이슈 #17 범위(목업 데이터로 뷰만 구현)라 실제 WorkoutRecord 연동은 하지 않는다.
//

import Foundation
import SwiftUI

enum AnalysisMockData {
    static let entries: [AnalysisEntry] = [
        AnalysisEntry(
            date: DateComponents(calendar: .current, year: 2026, month: 10, day: 28).date!,
            dateAndQuarter: "10월 28일 • 총 4Q",
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
                        quarterNumber: 1, durationText: "26:03", position: "CM", heatmapPageCount: 3,
                        events: [
                            AnalysisMatchEvent(type: .goal, timeText: "00:00", position: UnitPoint(x: 0.72, y: 0.72)),
                            AnalysisMatchEvent(type: .assist, timeText: "00:00", position: UnitPoint(x: 0.33, y: 0.42)),
                        ]
                    ),
                    AnalysisQuarter(quarterNumber: 2, durationText: "24:51", position: "CM", heatmapPageCount: 2),
                    AnalysisQuarter(
                        quarterNumber: 3, durationText: "25:10", position: "RW", heatmapPageCount: 3,
                        events: [
                            AnalysisMatchEvent(type: .goal, timeText: "00:00", position: UnitPoint(x: 0.6, y: 0.3)),
                        ]
                    ),
                    AnalysisQuarter(quarterNumber: 4, durationText: "23:40", position: "RW", heatmapPageCount: 2),
                ],
                keyStats: [
                    AnalysisStat(label: "최고속도", value: "22.6", unit: "km/h"),
                    AnalysisStat(label: "이동거리", value: "2.48", unit: "km"),
                    AnalysisStat(label: "소모칼로리", value: "245", unit: "kcal"),
                ],
                goalCount: 2,
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
                    AnalysisSection(title: "Training Load", rows: [
                        AnalysisSectionRow(label: "TRIMP", value: "86", unit: "AU"),
                        AnalysisSectionRow(label: "Player Load", value: "312", unit: "AU"),
                    ]),
                ],
                disclaimer: "히트맵과 포지션이 정확한지 확인해주세요"
            )
        ),
        AnalysisEntry(
            date: DateComponents(calendar: .current, year: 2026, month: 10, day: 21).date!,
            dateAndQuarter: "10월 21일 • 총 2Q",
            fieldName: "포스텍 풋살장",
            stats: [
                AnalysisStat(label: "최고속도", value: "19.4", unit: "km/h"),
                AnalysisStat(label: "이동거리", value: "1.72", unit: "km"),
                AnalysisStat(label: "소모칼로리", value: "168", unit: "kcal"),
            ],
            detail: AnalysisDetail(
                title: "10월 21일",
                quarters: [
                    AnalysisQuarter(quarterNumber: 1, durationText: "24:30", position: "GK", heatmapPageCount: 2),
                    AnalysisQuarter(quarterNumber: 2, durationText: "22:18", position: "GK", heatmapPageCount: 2),
                ],
                keyStats: [
                    AnalysisStat(label: "최고속도", value: "19.4", unit: "km/h"),
                    AnalysisStat(label: "이동거리", value: "1.72", unit: "km"),
                    AnalysisStat(label: "소모칼로리", value: "168", unit: "kcal"),
                ],
                goalCount: 0,
                assistCount: 0,
                sections: [
                    AnalysisSection(title: "Movement", rows: [
                        AnalysisSectionRow(label: "평균 속력", value: "6.1", unit: "km/h"),
                        AnalysisSectionRow(label: "고강도 주행거리", value: "210", unit: "m"),
                        AnalysisSectionRow(label: "방향 전환 횟수", value: "15", unit: "회"),
                        AnalysisSectionRow(label: "가속 횟수", value: "9", unit: "회"),
                        AnalysisSectionRow(label: "감속 횟수", value: "8", unit: "회"),
                    ]),
                    AnalysisSection(title: "Physical Activity", rows: [
                        AnalysisSectionRow(label: "최대 심박수", value: "156", unit: "bpm"),
                        AnalysisSectionRow(label: "평균 심박수", value: "121", unit: "bpm"),
                    ]),
                    AnalysisSection(title: "Training Load", rows: [
                        AnalysisSectionRow(label: "TRIMP", value: "52", unit: "AU"),
                        AnalysisSectionRow(label: "Player Load", value: "201", unit: "AU"),
                    ]),
                ],
                disclaimer: "히트맵과 포지션이 정확한지 확인해주세요"
            )
        ),
    ]

    /// `FriendsView`의 `UserProfile`을 그대로 재사용한다 — "함께 뛴 친구"용 별도 아이덴티티
    /// 모델을 새로 만들 이유가 없다.
    static let friendsPlayedTogether: [UserProfile] = [
        UserProfile(nickname: "갱아", status: .friend),
        UserProfile(nickname: "루디", status: .friend),
    ]
}
