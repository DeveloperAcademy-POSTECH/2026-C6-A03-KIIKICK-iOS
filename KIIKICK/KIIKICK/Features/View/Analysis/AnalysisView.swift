//
//  AnalysisView.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" (이슈 #17), 541:3658 "analysis_empty"(이슈 #43) —
//  목업 데이터(AnalysisMockData)로 구현. 실제 WorkoutRecord 연동은 이 이슈 범위 밖.
//

import SwiftUI

struct AnalysisView: View {
    @State private var year = 2026
    @State private var month = 10
    @State private var entries: [AnalysisEntry] = AnalysisMockData.entries
    @State private var pushedDetail: AnalysisEntry?

    private var availableYearMonths: [YearMonth] {
        Array(Set(entries.map {
            let comps = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return YearMonth(year: comps.year!, month: comps.month!)
        }))
    }

    private var entriesInSelectedMonth: [AnalysisEntry] {
        entries.filter {
            let comps = Calendar.current.dateComponents([.year, .month], from: $0.date)
            return comps.year == year && comps.month == month
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("분석")
                            .font(.head1B)
                            .foregroundStyle(.gray50)
                        EmptyStateView(
                            title: "아직 경기 기록이 없어요",
                            subtitle: "경기를 완료하면 이곳에서 분석 결과를 볼 수 있어요"
                        )
                        .padding(.top, 135)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DatePickerView(year: $year, month: $month, availableYearMonths: availableYearMonths)

                        ForEach(entriesInSelectedMonth) { entry in
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
            }
        }
        .background(Color.gray950)
        .navigationBarHidden(true)
        .navigationDestination(item: $pushedDetail) { entry in
            AnalysisDetailView(entry: entry)
        }
        .onAppear {
            if let first = availableYearMonths.sorted().last {
                year = first.year
                month = first.month
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisView()
    }
}
