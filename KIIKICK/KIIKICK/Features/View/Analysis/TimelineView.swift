//
//  TimelineView.swift
//  KIIKICK
//
//  Figma node 735:11160 "timeline" (이슈 #43) — AnalysisDetailView에서 히트맵 위
//  "타임라인 보기"를 누르면 들어오는 화면. 맵 + 재생 슬라이더 + 누적 통계 + 골/어시스트
//  타임라인(ListEventView)으로 구성된다.
//
//  슬라이더 시각까지의 최근 20초 포인트와 골/어시스트 핀을 지도에 표시한다.
//  이동거리와 칼로리는 시계열 샘플이 없어 쿼터 전체의 HealthKit 합계를 표시한다.
//
//  골/어시스트 핀은 node 735:11275처럼 맵 위 실제 좌표(AnalysisMatchEvent.position,
//  0...1 상대 좌표)에 찍는다 — FieldCoordinateMapper로 실제 GPS 좌표를 정규화한 값이다.
//

import SwiftUI

struct TimelineView: View {
    @Environment(\.dismiss) private var dismiss

    let dateTitle: String
    let quarter: AnalysisQuarter

    @State private var playbackTime: TimeInterval

    init(dateTitle: String, quarter: AnalysisQuarter) {
        self.dateTitle = dateTitle
        self.quarter = quarter
        _playbackTime = State(initialValue: min(TimelineWindow.length, max(0, quarter.duration)))
    }

    private var playbackTimeText: String {
        let seconds = max(0, Int(playbackTime))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return "\(minutes.formatted(.number.precision(.integerLength(2)))):\(remainingSeconds.formatted(.number.precision(.integerLength(2))))"
    }

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
        let window = quarter.startDate.map {
            TimelineWindow(quarterStart: $0, duration: quarter.duration, elapsed: playbackTime)
        }
        let visiblePoints = quarter.points.filter { window?.contains($0.timestamp) == true }
        let visibleEvents = quarter.events.filter { window?.contains($0.timestamp) == true }
        let currentSpeedKmh = max(0, visiblePoints.max(by: { $0.timestamp < $1.timestamp })?.speed ?? 0) * 3.6

        ScrollView {
            VStack(spacing: 24) {
                TrackingMapPager(
                    field: quarter.field,
                    points: visiblePoints,
                    isAttackDirectionReversed: quarter.isAttackDirectionReversed,
                    events: visibleEvents
                )
                .frame(height: 264)

                VStack(spacing: 4) {
                    Text(playbackTimeText)
                        .font(.title2SB)
                        .foregroundStyle(.colorTextPrimary)
                    Slider(value: $playbackTime, in: 0...max(quarter.duration, 1)) {
                        Text("재생 위치")
                    }
                        .tint(.mint500)
                        .disabled(quarter.startDate == nil || quarter.duration <= 0)
                        .accessibilityValue("\(playbackTimeText), 전체 \(quarter.durationText)")
                    Text(quarter.durationText)
                        .font(.caption1M)
                        .foregroundStyle(.colorTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                HStack(spacing: 28) {
                    timeStat(label: "누적 이동거리", value: quarter.totalDistanceKm.formatted(.number.precision(.fractionLength(2))), unit: "km")
                    timeStat(label: "누적 소모 칼로리", value: quarter.totalCaloriesKcal.formatted(.number.precision(.fractionLength(0))), unit: "kcal")
                    timeStat(label: "현재 속도", value: currentSpeedKmh.formatted(.number.precision(.fractionLength(1))), unit: "km/h")
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
                    .accessibilityLabel("뒤로 가기")
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
    let start = Date.now
    NavigationStack {
        TimelineView(
            dateTitle: "10월 28일",
            quarter: AnalysisQuarter(
                quarterNumber: 1, durationText: "26:03", startDate: start, duration: 1563,
                events: [
                    AnalysisMatchEvent(type: .goal, timeText: "03:12", timestamp: start.addingTimeInterval(192), position: UnitPoint(x: 0.72, y: 0.72)),
                    AnalysisMatchEvent(type: .assist, timeText: "11:40", timestamp: start.addingTimeInterval(700), position: UnitPoint(x: 0.33, y: 0.42)),
                ],
                totalDistanceKm: 2.48, totalCaloriesKcal: 245
            )
        )
    }
}
