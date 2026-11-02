//
//  AnalysisView.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" (이슈 #17). 목업 데이터(AnalysisMockData)로 구현 —
//  실제 WorkoutRecord 연동은 이 이슈 범위 밖.
//

import SwiftUI

struct AnalysisView: View {
    @State private var year = 2026
    @State private var month = 10
    @State private var entries: [AnalysisEntry] = AnalysisMockData.entries
    @State private var pushedDetail: AnalysisEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DatePickerView(year: $year, month: $month)

                ForEach(entries) { entry in
                    CardSummaryView(
                        dateAndQuarter: entry.dateAndQuarter,
                        fieldName: entry.fieldName,
                        stats: entry.stats.map { CardSummaryView.Stat(label: $0.label, value: $0.value, unit: $0.unit) },
                        action: { pushedDetail = entry }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.gray950)
        .navigationBarHidden(true)
        .navigationDestination(item: $pushedDetail) { entry in
            AnalysisDetailView(entry: entry)
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisView()
    }
}
