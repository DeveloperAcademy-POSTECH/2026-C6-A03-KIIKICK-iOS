//
//  IntervalView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct IntervalView: View {

    let lastQuarter: QuarterRecord
    var startQuarter: () -> Void
    var finishGame: () -> Void

    @State private var selectedPage = 0

    private var durationText: String {
        let duration = Int(lastQuarter.endDate.timeIntervalSince(lastQuarter.startDate))
        return String(format: "%02d:%02d", duration / 60, duration % 60)
    }

    var body: some View {
        TabView(selection: $selectedPage) {
            VStack(spacing: 16) {
                Text(verbatim: "Q\(lastQuarter.quarterNumber) 종료")
                    .font(.title1SB)
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Match Time")
                            .font(.caption1M)
                        Text(verbatim: durationText)
                            .font(.title4SB)
                    }
                    BtnSelectionView(text: lastQuarter.position?.uppercased ?? "-", style: .selected, action: {})
                }
                HStack {
                    Image(systemName: "soccerball.inverse")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                    Text(verbatim: "\(lastQuarter.goalCount)")
                        .font(.body4R)
                    Image(systemName: "shoe.running.and.shadow.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                    Text(verbatim: "\(lastQuarter.assistCount)")
                        .font(.body4R)
                }
            }
            .tag(0)
            VStack(spacing: 8) {
                CtaWatchView(text: "새 쿼터 시작", type: .primary, action: {startQuarter()})
                CtaWatchView(text: "경기 종료", type: .destructive, action: {finishGame()})
            }
            .tag(1)
        }
        .tabViewStyle(.verticalPage)
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { selectedPage = 1 }
        }
    }
}
