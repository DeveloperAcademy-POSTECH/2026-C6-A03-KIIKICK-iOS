//
//  IntervalView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

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
