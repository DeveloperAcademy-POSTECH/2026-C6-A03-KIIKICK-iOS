//
//  IntervalView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct IntervalView: View {
    
    var quarterNumber: Int = 1
    var position: Position
    var startQuarter: () -> Void
    var finishGame: () -> Void
    
    var body: some View {
        TabView {
            VStack(spacing: 16) {
                Text("Q\(quarterNumber) 종료")
                    .font(.title1SB)
                HStack(spacing: 24 ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Match Time")
                            .font(.caption1M)
                        Text("12:34")
                            .font(.title4SB)
                    }
                    BtnSelectionView(text: position.uppercased, style: .selected, action: {})
                }
                HStack {
                    Image(systemName: "soccerball.inverse")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                    Text("3")
                        .font(.body4R)
                    Image(systemName: "shoe.running.and.shadow.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                    Text("1")
                        .font(.body4R)
                }
            }
            VStack(spacing: 8) {
                CtaWatchView(text: "새 쿼터 시작", type: .primary, action: {startQuarter()})
                CtaWatchView(text: "경기 종료", type: .destructive, action: {finishGame()})
            }
        }.tabViewStyle(.verticalPage)
    }
}
