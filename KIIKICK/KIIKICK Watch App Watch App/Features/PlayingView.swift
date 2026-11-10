//
//  PlayingView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI
import WatchKit

struct PlayingView: View {

    enum ScoreType: String {
        case goal, assist

        /// 득점과 어시스트를 화면을 보지 않고도 구분할 수 있는 기본 햅틱.
        var hapticType: WKHapticType {
            switch self {
            case .goal: .success
            case .assist: .directionUp
            }
        }

        var icon: Image {
            switch self {
            case .goal:
                Image(systemName: "soccerball.inverse")
            case .assist:
                Image(systemName: "shoe.running.and.shadow.fill")
            }
        }
    }

    /// 지금 쿼터가 시작된 시각 — 라이브 타이머용.
    let quarterStartDate: Date
    /// 골/어시스트를 누른 순간의 위치를 기록하는 데 쓴다.
    let workoutManager: WorkoutManager
    /// 쿼터 종료 시 지금까지 기록된 득점/어시스트 개수를 넘겨준다.
    var action: (_ goalCount: Int, _ assistCount: Int) -> Void

    @State private var goalCount = 0
    @State private var assistCount = 0

    var body: some View {
        TabView {
            RecordEditView(type: .goal, count: $goalCount, quarterStartDate: quarterStartDate, workoutManager: workoutManager)
            RecordEditView(type: .assist, count: $assistCount, quarterStartDate: quarterStartDate, workoutManager: workoutManager)
            QuarterSetView(action: { action(goalCount, assistCount) })
        }.tabViewStyle(.verticalPage)
    }


    struct RecordEditView: View {

        @State var type: ScoreType
        @Binding var count: Int
        let quarterStartDate: Date
        let workoutManager: WorkoutManager

        private var eventType: MatchEventType { type == .goal ? .goal : .assist }

        var body: some View {
            GeometryReader { geo in
                VStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match Time")
                            .font(.caption1M)
                        HStack(alignment: .center) {
                            Text(quarterStartDate, style: .timer)
                                .font(.title4SB)
                            Spacer()
                            HStack(spacing: 4) {
                                type.icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                Text("\(type.rawValue.uppercased())")
                                    .font(.body4R)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                    StepperWatchView(
                        count: $count,
                        onIncrement: incrementScore,
                        onDecrement: { workoutManager.removeLastEvent(type: eventType) }
                    )
                    .frame(width: geo.size.width - 32)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }

        private func incrementScore() {
            workoutManager.recordEvent(type: eventType)
            // GPS 수신 전에도 카운트는 증가하므로 입력 피드백은 항상 제공한다.
            WKInterfaceDevice.current().play(type.hapticType)
        }
    }

    struct QuarterSetView: View {
        var action: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                ProgressWatchButton()
                CtaWatchView(text: "쿼터 종료", type: .destructive, action: { action() })
            }
        }
    }
}
