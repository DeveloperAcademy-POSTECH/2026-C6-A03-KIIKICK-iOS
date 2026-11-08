//
//  AnalysisView.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" (이슈 #17). 실제 WorkoutRecord 연동은 이 이슈 범위
//  밖이라 목업 데이터를 치워서 당장은 빈 목록으로 시작한다.
//

import SwiftUI

struct AnalysisView: View {
    @State private var year = 2026
    @State private var month = 10
    @State private var entries: [AnalysisEntry] = []
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
