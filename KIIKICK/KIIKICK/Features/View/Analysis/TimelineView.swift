//
//  TimelineView.swift
//  KIIKICK
//
//  Figma node 735:11160 "timeline" (이슈 #43) — AnalysisDetailView에서 히트맵 위
//  "타임라인 보기"를 누르면 들어오는 화면. 맵 + 재생 슬라이더 + 누적 통계 + 골/어시스트
//  타임라인(ListEventView)으로 구성된다.
//
//  DESIGN-GAP: 슬라이더는 실제 쿼터 재생/트랙포인트 데이터와 연동돼 있지 않다 — 그런
//  시계열 재생 파이프라인 자체가 아직 없다(AGENTS.md "구간 재생" 기능은 범위 밖). 지금은
//  보여주기용 정적 값이다. 누적 이동거리/소모칼로리/최고속도와 이벤트 시각은 전부
//  AnalysisEntry+WorkoutRecord.swift가 실제 WorkoutRecord에서 계산한 값이다.
//
//  골/어시스트 핀은 node 735:11275처럼 맵 위 실제 좌표(AnalysisMatchEvent.position,
//  0...1 상대 좌표)에 찍는다 — FieldCoordinateMapper로 실제 GPS 좌표를 정규화한 값이다.
//

import SwiftUI

struct TimelineView: View {
    @Environment(\.dismiss) private var dismiss

    let dateTitle: String
    let quarter: AnalysisQuarter

    @State private var sliderValue: Double = 0.42

    private var numberedEvents: [(event: AnalysisMatchEvent, number: Int)] {
        var goalIndex = 0
        var assistIndex = 0
        return quarter.events.map { event in
            switch event.type {
            case .goal:
                goalIndex += 1
                return (event, goalIndex)
            case .assist:
                assistIndex += 1
                return (event, assistIndex)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                mapViewer

                VStack(spacing: 4) {
                    Text("02:35")
                        .font(.title2SB)
                        .foregroundStyle(.colorTextPrimary)
                    Slider(value: $sliderValue)
                        .tint(.mint500)
                    Text(quarter.durationText)
                        .font(.caption1M)
                        .foregroundStyle(.colorTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                HStack(spacing: 28) {
                    timeStat(label: "누적 이동거리", value: String(format: "%.2f", quarter.totalDistanceKm), unit: "km")
                    timeStat(label: "누적 소모 칼로리", value: String(format: "%.0f", quarter.totalCaloriesKcal), unit: "kcal")
                    timeStat(label: "현재 속도", value: String(format: "%.1f", quarter.maxSpeedKmh), unit: "km/h")
                }

                if numberedEvents.isEmpty {
                    Text("이 쿼터엔 골·어시스트 기록이 없어요")
                        .font(.body4R)
                        .foregroundStyle(.gray500)
                } else {
                    VStack(spacing: 12) {
                        ForEach(numberedEvents, id: \.event.id) { item in
                            ListEventView(type: item.event.type, number: item.number, timeText: item.event.timeText)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(dateTitle)
                        .font(.head3B)
                    Text("\(quarter.quarterNumber) 쿼터")
                        .font(.label2SB)
                }
                .foregroundStyle(.colorTextPrimary)
            }
        }
    }

    private var mapViewer: some View {
        TrackingMapPager(field: quarter.field, points: quarter.points,
                         isAttackDirectionReversed: quarter.isAttackDirectionReversed,
                         events: quarter.events)
            .frame(height: 264)
    }

    private func timeStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.label2SB)
                .foregroundStyle(.colorTextPrimary)
            VStack(spacing: 0) {
                Text(value)
                    .font(.display3SB)
                    .foregroundStyle(.colorTextPrimary)
                Text(unit)
                    .font(.body4R)
                    .foregroundStyle(.colorTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TimelineView(
            dateTitle: "10월 28일",
            quarter: AnalysisQuarter(
                quarterNumber: 1, durationText: "26:03",
                events: [
                    AnalysisMatchEvent(type: .goal, timeText: "03:12", position: UnitPoint(x: 0.72, y: 0.72)),
                    AnalysisMatchEvent(type: .assist, timeText: "11:40", position: UnitPoint(x: 0.33, y: 0.42)),
                ],
                totalDistanceKm: 2.48, totalCaloriesKcal: 245
            )
        )
    }
}
