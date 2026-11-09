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

    /// 이슈 #50 — 지금까지 처리한 강제 종료 요청의 타임스탬프. 경기를 새로 시작할 때마다
    /// 현재 시각으로 갱신해서, applicationContext에 남아있던 "이전 경기" 요청이 새
    /// 경기를 잘못 끝내버리지 않게 막는다.
    @State private var forceEndBaseline: TimeInterval = 0

    var body: some View {
        ZStack {
            switch step {
            case .start:
                // iOS에서 운동장을 골라 경기를 생성하기 전까진(SessionManager.
                // preparedFieldName == nil) "경기 시작" 버튼 대신 대기 화면을 보여준다.
                // 경기가 끝나고 돌아왔을 때도 다음 경기가 준비되기 전까진 이 Default
                // 상태 그대로다(HomeView가 경기 시작 시점에 이미 비워서 보내준다).
                if SessionManager.shared.preparedFieldName != nil {
                    StartView() { step = .countDown }
                } else {
                    WaitingForMatchView()
                }
            case .countDown:
                CountDownView {
                    Task {
                        forceEndBaseline = Date().timeIntervalSince1970
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
        .onChange(of: SessionManager.shared.forceEndRequestedAt) { _, newValue in
            handleForceEnd(requestedAt: newValue)
        }
    }

    /// 이슈 #50 — iOS의 "강제로 경기 종료하기"가 보낸 신호를 처리한다. 지금이 `.playing`
    /// (한창 쿼터 진행 중) 또는 `.position`(쿼터는 끝났지만 포지션을 아직 안 고른 상태)
    /// 이면 그 쿼터를 포지션 없이(position: nil) 강제로 끝내서 기록을 남긴다 — 포지션은
    /// 나중에 iOS "분석 준비" 화면에서 채워 넣는다(ReadyForDetailView 참고). `.interval`
    /// 이면 직전 쿼터는 이미 끝나 있으니 추가로 끝낼 쿼터가 없다. `.start`/`.countDown`/
    /// `.end`는 경기가 아직 시작 전이거나 이미 끝난 상태라 무시한다.
    private func handleForceEnd(requestedAt: TimeInterval?) {
        guard let requestedAt, requestedAt > forceEndBaseline else { return }
        forceEndBaseline = requestedAt

        switch step {
        case .playing, .position:
            let (record, payload) = workoutManager.endQuarter(
                quarterNumber: quarterNumber,
                position: nil,
                goalCount: pendingGoalCount,
                assistCount: pendingAssistCount
            )
            modelContext.insert(record)
            try? modelContext.save()
            SessionManager.shared.send(payload: payload, recordID: record.id)
        case .interval:
            break
        case .start, .countDown, .end:
            return
        }

        Task {
            await workoutManager.finishMatch()
            SessionManager.shared.updateMatchStatus(isInProgress: false)
            quarterNumber = 1
            pendingGoalCount = 0
            pendingAssistCount = 0
            lastQuarter = nil
            step = .end
        }
    }
}
