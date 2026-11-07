//
//  MainView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI
import SwiftData

struct MainView: View {

    private enum Step: Int, CaseIterable { case start, countDown, playing, position, interval, end }

    @State private var step: Step = .start
    @State private var workoutManager = WorkoutManager()
    @Environment(\.modelContext) private var modelContext

    @State private var quarterNumber = 1
    @State private var pendingGoalCount = 0
    @State private var pendingAssistCount = 0
    @State private var lastQuarter: QuarterRecord?

    var body: some View {
        ZStack {
            switch step {
            case .start:
                StartView() { step = .countDown }
            case .countDown:
                CountDownView {
                    Task {
                        await workoutManager.startMatch()
                        workoutManager.beginQuarter()
                        SessionManager.shared.updateMatchStatus(isInProgress: true)
                        step = .playing
                    }
                }
            case .playing:
                PlayingView(quarterStartDate: workoutManager.currentQuarterStartDate ?? Date(), workoutManager: workoutManager) { goalCount, assistCount in
                    pendingGoalCount = goalCount
                    pendingAssistCount = assistCount
                    step = .position
                }
            case .position:
                PositionView { position in
                    // 쿼터 하나 = WorkoutPayload 하나. 로컬에 저장해두고 바로 보낸다 —
                    // 전송이 성공하면 SessionManager가 같은 id의 기록을 지운다.
                    let (record, payload) = workoutManager.endQuarter(
                        quarterNumber: quarterNumber,
                        position: position,
                        goalCount: pendingGoalCount,
                        assistCount: pendingAssistCount
                    )
                    modelContext.insert(record)
                    try? modelContext.save()
                    SessionManager.shared.send(payload: payload, recordID: record.id)
                    lastQuarter = record
                    step = .interval
                }
            case .interval:
                if let lastQuarter {
                    IntervalView(
                        lastQuarter: lastQuarter,
                        startQuarter: {
                            quarterNumber += 1
                            pendingGoalCount = 0
                            pendingAssistCount = 0
                            workoutManager.beginQuarter()
                            step = .playing
                        },
                        finishGame: {
                            Task {
                                await workoutManager.finishMatch()
                                SessionManager.shared.updateMatchStatus(isInProgress: false)
                                step = .end
                            }
                        }
                    )
                }
            case .end:
                EndView {
                    quarterNumber = 1
                    lastQuarter = nil
                    step = .start
                }
            }
        }
        .transition(.slide)
        .animation(.easeInOut, value: step)
    }
}
