//
//  MainView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct MainView: View {
    
    private enum Step: Int, CaseIterable { case start, countDown, playing, position, interval, end }
    
    @State private var step: Step = .interval
    
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
                IntervalView(position: .lw, startQuarter: {
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
