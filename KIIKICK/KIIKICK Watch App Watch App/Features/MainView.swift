//
//  MainView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct MainView: View {
    
    enum Step: Int, CaseIterable { case start, countDown, playing, position, interval, end }
    
    @State private var step: Step = .start
    
    var body: some View {
        ZStack {
            switch step {
            case .start:
                StartView() { step = .countDown }
            case .countDown:
                CountDownView { step = .playing }
            case .playing:
                PlayingView { step = .position }
            case .position:
                PositionView { step = .interval }
            case .interval:
                IntervalView(startQuarter: {
                    step = .playing
                }, finishGame: {
                    step = .end
                })
            case .end:
                EndView { step = .start }
            }
        }
        .transition(.slide)
        .animation(.easeInOut, value: step)
    }
}

struct EndView: View {
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130)
            Text("iPhone에서\n 경기를 준비해주세요")
        }
        .task {
            do {
                try await Task.sleep(for: .seconds(2))
                action()
            } catch {
                // 뷰 해제되었을 때
            }
        }
    }
}

struct PositionView: View {
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            Text("포지션을 선택하세요")
                .font(Font.body4R)
            HStack(spacing: 8) {
                BtnSelectionView { action() }
                BtnSelectionView { action() }
                BtnSelectionView { action() }
            }
            HStack(spacing: 8) {
                BtnSelectionView { action() }
                BtnSelectionView { action() }
                BtnSelectionView { action() }
            }
            HStack(spacing: 8) {
                BtnSelectionView { action() }
                BtnSelectionView { action() }
                BtnSelectionView { action() }
            }
            BtnSelectionView { }
        }
    }
}

struct IntervalView: View {
    
    var startQuarter: () -> Void
    var finishGame: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            CtaWatchView(text: "새 쿼터 시작", type: .primary, action: {startQuarter()})
            CtaWatchView(text: "경기 종료", type: .destructive, action: {finishGame()})
        }
    }
}

struct StartView: View {
    
    var action: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130)
                Spacer()
                CtaWatchView(text: "경기 시작", type: .primary, action: {action()})
                    .frame(maxWidth: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(12)
        .ignoresSafeArea()
    }
}

struct CountDownView: View {
    
    var action: () -> Void
    
    @State var time: Int = 3
    
    var body: some View {
        Text("\(time)")
            .font(.custom("Pretendard-SemiBold", size: 68))
            .task {
                do {
                    while time > 1 {
                        try await Task.sleep(for: .seconds(1))
                        time -= 1
                    }
                    try await Task.sleep(for: .seconds(1))
                    action()
                } catch {
                    // 뷰가 사라져서 취소된 경우
                }
            }
            .onTapGesture {
                action()
            }
    }
}

struct PlayingView: View {
    
    enum ScoreType: String {
        case goal, assist
        
        var icon: Image {
            switch self {
            case .goal:
                Image(systemName: "soccerball.inverse")
            case .assist:
                Image(systemName: "shoe.running.and.shadow.fill")
            }
        }
    }
    

    var action: () -> Void

    var body: some View {
        TabView {
            RecordEditView(type: .goal)
            RecordEditView(type: .assist)
            QuarterSetView(action: action)
        }.tabViewStyle(.verticalPage)
    }
    
    
    struct RecordEditView: View {
        
        @State var type: ScoreType
        
        var body: some View {
            GeometryReader { geo in
                VStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match Time")
                            .font(.caption1M)
                        HStack(alignment: .center) {
                            Text("12:34")
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
                    StepperViewWatch()
                        .frame(width: geo.size.width - 32)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
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

#Preview {
    MainView()
}
