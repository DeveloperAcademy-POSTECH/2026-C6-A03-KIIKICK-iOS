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
//  용 정적 값이고, 맵 위의 골/어시스트 핀 위치도 Figma 목업과 같은 장식용 좌표다.
//  이벤트 목록의 "00:00"도 실제 타임스탬프가 없어 Figma 목업 그대로 고정값이다.
//

import SwiftUI

struct TimelineView: View {
    @Environment(\.dismiss) private var dismiss

    let dateTitle: String
    let quarter: AnalysisQuarter

    @State private var sliderValue: Double = 0.42

    private var events: [(type: TimelineEventType, number: Int)] {
        (1...max(quarter.goalCount, 1)).compactMap { quarter.goalCount >= $0 ? (.goal, $0) : nil }
            + (1...max(quarter.assistCount, 1)).compactMap { quarter.assistCount >= $0 ? (.assist, $0) : nil }
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

                if events.isEmpty {
                    Text("이 쿼터엔 골·어시스트 기록이 없어요")
                        .font(.body4R)
                        .foregroundStyle(.gray500)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                            ListEventView(type: event.type, number: event.number, timeText: "00:00")
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
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray850)
            .frame(height: 236)
            .overlay(
                Image(systemName: "map")
                    .font(.system(size: 32))
                    .foregroundStyle(.gray500)
            )
            .overlay(alignment: .topTrailing) {
                if quarter.goalCount > 0 {
                    Image("ic_goal").renderingMode(.original).resizable().frame(width: 28, height: 28).padding(12)
                }
            }
            .overlay(alignment: .topLeading) {
                if quarter.assistCount > 0 {
                    Image("ic_assist").renderingMode(.original).resizable().frame(width: 28, height: 28).padding(12)
                }
            }
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
            quarter: AnalysisQuarter(quarterNumber: 1, durationText: "26:03", position: "CM", heatmapPageCount: 3, goalCount: 1, assistCount: 1)
        )
    }
}
