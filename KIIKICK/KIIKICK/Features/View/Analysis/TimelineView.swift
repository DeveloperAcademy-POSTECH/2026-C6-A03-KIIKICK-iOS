//
//  TimelineView.swift
//  KIIKICK
//
//  Figma node 735:11160 "timeline" (이슈 #43) — AnalysisDetailView에서 히트맵 위
//  "타임라인 보기"를 누르면 들어오는 화면. 맵 + 재생 슬라이더 + 누적 통계 + 골/어시스트
//  타임라인(ListEventView)으로 구성된다.
//
//  DESIGN-GAP: 슬라이더는 실제 쿼터 재생/트랙포인트 데이터와 연동돼 있지 않다 — 그런
//  시계열 데이터 자체가 아직 없다(AGENTS.md "구간 재생" 기능은 범위 밖). 지금은 보여주기
//  용 정적 값이다. 이벤트 목록의 "00:00"도 실제 타임스탬프가 없어 Figma 목업 그대로
//  고정값이다.
//
//  골/어시스트 핀은 node 735:11275처럼 맵 위 실제 좌표(AnalysisMatchEvent.position,
//  0...1 상대 좌표)에 찍는다 — 워치 쪽은 이미 골/어시스트를 누른 순간의 실제 위치를
//  MatchEvent로 기록해서 보내지만(WorkoutManager.recordEvent), Analysis 화면은 여전히
//  AnalysisMockData 목업만 보여주므로(WorkoutRecord 연동은 이 이슈 범위 밖) 좌표도 목업값.
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
                    timeStat(label: "누적 이동거리", value: "2.48", unit: "km")
                    timeStat(label: "누적 소모 칼로리", value: "245", unit: "kcal")
                    timeStat(label: "현재 속도", value: "22.6", unit: "km/h")
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
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray850)
                Image(systemName: "map")
                    .font(.system(size: 32))
                    .foregroundStyle(.gray500)
                    .frame(width: geo.size.width, height: geo.size.height)

                ForEach(quarter.events) { event in
                    Image(event.type.iconName)
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .position(x: event.position.x * geo.size.width, y: event.position.y * geo.size.height)
                }
            }
        }
        .frame(height: 236)
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
                quarterNumber: 1, durationText: "26:03", position: "CM", heatmapPageCount: 3,
                events: [
                    AnalysisMatchEvent(type: .goal, timeText: "00:00", position: UnitPoint(x: 0.72, y: 0.72)),
                    AnalysisMatchEvent(type: .assist, timeText: "00:00", position: UnitPoint(x: 0.33, y: 0.42)),
                ]
            )
        )
    }
}
