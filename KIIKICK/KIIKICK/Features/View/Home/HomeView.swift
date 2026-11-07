//
//  HomeView.swift
//  KIIKICK
//
//  이슈 #42: Figma "overall" 프레임 계열 기준으로 다시 구성했다. 구성: 상단 바(로고 +
//  새 경기 + 알림) → 상태 배너(MatchStatusHeaderView) → Overall 점수/통계
//  (OverallSummaryView) → 기록이 있을 때만 PerformanceTrendsView.
//
//  DESIGN-GAP: 탭바 아이콘(ic_ovr류)을 받지 못해 SF Symbol로 대체했다 — MainView.swift
//  주석 참고.
//
//  데이터 관련 TODO 모음(전부 "View만 먼저 만든다"는 전제로 자리만 잡아둔 부분):
//  - overallStat: 서버 Overall API가 아직 없다(OverallStat.swift 참고). 항상 .empty.
//  - PerformanceTrendsView에 넘기는 포인트 배열: 쿼터별 추세 집계 로직이 아직 없어
//    항상 빈 배열이다. 실제 집계가 생기면 selectedMetric에 따라 분기해서 채울 것.
//  - 총 경기 수/총 이동거리/평균 소모 칼로리는 지금 있는 로컬 SwiftData 기록에서 바로
//    계산한다(가짜 데이터 아님) — 다만 나중에 서버 집계 API가 생기면 그쪽으로 옮길 수도
//    있다.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    
    @State private var preparedField: Field?
    @State private var isSelectingField = false
    @State private var selectedMetric: PerformanceMetric = .overall
    
    // TODO: 서버 Overall API 연동 전까지는 항상 비어있다. OverallStat.swift 참고.
    @State private var overallStat: OverallStat = .empty
    
    private var matchState: HomeMatchState {
        if sessionManager.isMatchInProgress {
            return .inProgress
        }
        if let record = sessionManager.justArrivedRecord {
            return .justFinished(record: record)
        }
        if let preparedField {
            return .prepared(fieldName: preparedField.name)
        }
        if !sessionManager.isReachable {
            return .watchDisconnected
        }
        if records.isEmpty {
            return .noRecords
        }
        return .idle
    }
    
    private var totalDistanceKm: Double {
        records.reduce(0) { $0 + $1.totalDistance } / 1000
    }
    
    private var avgCalories: Int {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.totalCalories }
        return Int(total / Double(records.count))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBar
                
                MatchStatusHeaderView(
                    state: matchState,
                    onPrepareMatch: { isSelectingField = true },
                    onForceEndMatch: {
                        // TODO: 워치 쪽에 "강제 종료"를 전달하는 API가 아직 없어 UI만 구현.
                    }
                )
                .padding(.horizontal, 24)
                
                OverallSummaryView(
                    stat: overallStat,
                    matchCount: records.count,
                    totalDistanceKm: totalDistanceKm,
                    avgCalories: avgCalories
                )
                .padding(.horizontal, 24)
                
                if !records.isEmpty {
                    PerformanceTrendsView(
                        selectedMetric: $selectedMetric,
                        // TODO: 쿼터별 추세 집계가 아직 없어 항상 빈 배열 — 그래프 자리만 보여준다.
                        points: [],
                        unit: selectedMetric == .overall ? "OVR" : "",
                        dateLabel: "",
                        yAxisValues: [0, 25, 50, 75, 100]
                    )
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.gray950)
        .navigationDestination(isPresented: $isSelectingField) {
            FieldListView(onSelect: { field in
                preparedField = field
                isSelectingField = false
            })
        }
        .onChange(of: sessionManager.isMatchInProgress) { _, isInProgress in
            if isInProgress { preparedField = nil }
        }
        .navigationDestination(for: WorkoutRecord.self) { record in
            WorkoutDetailView(record: record)
                .toolbar(.hidden, for: .tabBar)
                .onAppear {
                    if sessionManager.justArrivedRecord?.persistentModelID == record.persistentModelID {
                        sessionManager.justArrivedRecord = nil
                    }
                }
        }
    }
    
    private var headerBar: some View {
        HStack {
            Image("LogoFull")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 22)
            
            Spacer()
            
            Button { isSelectingField = true } label: {
                Image("ic_plus")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(.brandPrimary)
                    .frame(width: 44, height: 44)
                    .glassCircleBackground()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            
            NavigationLink(destination: NotificationListView()) {
                Image("ic_bell")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.colorTextPrimary)
                    .frame(width: 44, height: 44)
                    .glassCircleBackground()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
