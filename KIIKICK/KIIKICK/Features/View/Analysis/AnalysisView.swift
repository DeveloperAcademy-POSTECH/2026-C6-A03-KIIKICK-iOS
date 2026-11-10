//
//  AnalysisView.swift
//  KIIKICK
//
//  Figma node 331:2810 "analysis" (이슈 #17), 541:3658 "analysis_empty"(이슈 #43) —
//  AnalysisMockData를 치우고 실제 WorkoutRecord에서 목록을 만든다. 쿼터 하나 =
//  WorkoutRecord 하나라서, 한 경기 안에서 연달아 기록된 WorkoutRecord들을 모으면
//  그게 경기(AnalysisEntry) 하나다 — 묶는 로직은 AnalysisEntry+WorkoutRecord.swift.
//
//  이슈 #50 확인 중 발견: 원래는 "같은 날짜(달력 기준)·같은 운동장"으로 묶었는데,
//  WorkoutPayload에 매치 세션을 구분할 ID가 없어서(DESIGN-GAP, AnalysisQuarter.position
//  주석 참고) 같은 날 테스트를 여러 번 하면 전부 "하루 = 경기 1개"로 합쳐져 홈 탭의
//  "총 경기 수"는 늘어도 분석 탭 카드 수는 안 늘어나는 버그가 있었다. 지금은 "직전
//  쿼터가 끝난 시각(date+duration) 대비 이 레코드가 matchGroupingGap 안에서 시작했는지"
//  로 묶는다 — 진짜 매치 ID가 생기기 전까지의 휴리스틱이다.
//
//  처음 경기 카드를 누르면 분석 플로우대로
//  ReadyForDetailView(포지션/반전 확인) → AnalyzingView(분석 중) → AnalysisDetailView
//  순서를 거친다. 분석 보기를 저장한 경기는 상세로 바로 이동한다.
//
//  이 세 화면은 전부 router.paths[.analysis](AppRouter가 들고 있는 NavigationPath)에
//  직접 쌓는다 — item/isPresented 기반 로컬 push로는 "분석이 끝나면 ready+analyzing을
//  건너뛰고 detail만 남긴다"를 할 수 없기 때문이다(NavigationPath는 removeLast(n)이
//  되지만 로컬 push 상태는 한 단계씩만 떼어낼 수 있다). AnalysisDetailView에서 뒤로
//  가면 ready/analyzing이 이미 스택에서 빠져 있어서 바로 이 화면(AnalysisView)으로
//  돌아온다.
//

import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    @State private var year = 2026
    @State private var month = 10

    private var entries: [AnalysisEntry] {
        AnalysisEntry.grouped(from: records)
    }

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
                                action: { router.showAnalysis(entry, in: .analysis) }
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
        .onAppear {
            syncToLatestMonthIfNeeded()
        }
        .onChange(of: records) { _, _ in
            // 탭이 계속 떠 있는 동안(TabView가 형제 탭을 메모리에서 안 지운다) 새 경기가
            // 도착해도 .onAppear는 다시 안 불린다 — year/month가 예전 달에 멈춰 있으면
            // entries엔 있는데 entriesInSelectedMonth만 비어서 "경기가 안 보이는" 것처럼
            // 보였다(이슈 #50 확인 중 발견). records가 바뀔 때마다 다시 확인한다.
            syncToLatestMonthIfNeeded()
        }
    }

    /// 지금 선택된 (year, month)에 보여줄 경기가 없을 때만 최신 달로 이동한다 — 사용자가
    /// 과거 달을 직접 보고 있는 중이면 끼어들지 않는다.
    private func syncToLatestMonthIfNeeded() {
        guard entriesInSelectedMonth.isEmpty, let latest = availableYearMonths.sorted().last else { return }
        year = latest.year
        month = latest.month
    }
}

#Preview {
    NavigationStack {
        AnalysisView()
    }
    .environment(AppRouter())
}
