//
//  AnalysisView.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" (이슈 #17), 541:3658 "analysis_empty"(이슈 #43) —
//  목업 데이터(AnalysisMockData)로 구현. 실제 WorkoutRecord 연동은 이 이슈 범위 밖.
//
//  경기 카드를 누르면 분석 상세로 바로 가지 않고, 분석 플로우대로
//  ReadyForDetailView(포지션/반전 확인) → AnalyzingView(분석 중) → AnalysisDetailView
//  순서를 거친다.
//
//  이 세 화면은 전부 router.paths[.analysis](AppRouter가 들고 있는 NavigationPath)에
//  직접 쌓는다 — item/isPresented 기반 로컬 push로는 "분석이 끝나면 ready+analyzing을
//  건너뛰고 detail만 남긴다"를 할 수 없기 때문이다(NavigationPath는 removeLast(n)이
//  되지만 로컬 push 상태는 한 단계씩만 떼어낼 수 있다). AnalysisDetailView에서 뒤로
//  가면 ready/analyzing이 이미 스택에서 빠져 있어서 바로 이 화면(AnalysisView)으로
//  돌아온다.
//

import SwiftUI

enum AnalysisRoute: Hashable {
    case ready(AnalysisEntry)
    case analyzing(AnalysisEntry)
    case detail(AnalysisEntry)
}

struct AnalysisView: View {
    @Environment(AppRouter.self) private var router

    @State private var year = 2026
    @State private var month = 10
    @State private var entries: [AnalysisEntry] = AnalysisMockData.entries

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
                                action: { router.paths[.analysis, default: .init()].append(AnalysisRoute.ready(entry)) }
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
        .navigationDestination(for: AnalysisRoute.self) { route in
            switch route {
            case .ready(let entry):
                ReadyForDetailView(entry: entry)
            case .analyzing(let entry):
                AnalyzingView(entry: entry)
            case .detail(let entry):
                AnalysisDetailView(entry: entry)
            }
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
    .environment(AppRouter())
}
