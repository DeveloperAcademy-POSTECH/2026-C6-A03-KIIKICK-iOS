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
//  완료된 쿼터의 누적 지표를 OverallCalculator로 계산한다. DEBUG 목업은 저장하지 않는다.
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
    
    @State private var overallHistory: OverallHistory = .empty
    #if DEBUG
    @AppStorage(OverallMockData.enabledKey) private var usesMockData = true
    #else
    private var usesMockData: Bool { false }
    #endif

    private struct OverallSource: Equatable {
        let usesMockData: Bool
        let inputs: [OverallWorkoutInput]
    }

    private var overallSource: OverallSource {
        OverallSource(
            usesMockData: usesMockData,
            inputs: usesMockData ? [] : records.map(OverallWorkoutInput.init(record:))
        )
    }

    private var overallStat: OverallStat {
        OverallStat(score: overallHistory.current?.score, delta: overallHistory.delta)
    }

    private var trendPoints: [PerformanceTrendPoint] {
        overallHistory.workouts.enumerated().map { index, workout in
            let value: Double
            switch selectedMetric {
            case .overall: value = Double(overallHistory.cumulative[index].score)
            case .speed: value = workout.peakSpeedKmh
            case .distance: value = workout.distanceMeters / 1000
            case .calories: value = workout.calories
            }
            return PerformanceTrendPoint(quarterIndex: index + 1, value: value)
        }
    }

    private var trendUnit: String {
        switch selectedMetric {
        case .overall: "OVR"
        case .speed: "km/h"
        case .distance: "km"
        case .calories: "kcal"
        }
    }

    private var trendAxis: [Double] {
        let maximum = max(trendPoints.map(\.value).max() ?? 0, selectedMetric == .overall ? 100 : 1)
        let step = max(1, ceil(maximum / 4))
        return (0...4).map { Double($0) * step }
    }

    private var trendDate: String {
        guard let date = overallHistory.workouts.last?.date else { return "" }
        return "\(date.formatted(.dateTime.month().day())) · Q\(overallHistory.workouts.count)"
    }
    
    private var matchState: HomeMatchState {
        if sessionManager.isMatchInProgress {
            return .inProgress
        }
        // 경기가 막 도착했을 때도 더 이상 배너를 안 띄운다 — 그 이벤트는 알림으로 간다
        // (SessionManager.didReceive(file:) 참고). 바로 다음 상태로 넘어간다.
        if let preparedField {
            return .prepared(fieldName: preparedField.name)
        }
        if !sessionManager.isReachable {
            return .watchDisconnected
        }
        if overallHistory.workouts.isEmpty {
            return .noRecords
        }
        return .idle
    }
    
    private var hasUnreadNotifications: Bool {
        sessionManager.notifications.contains { !$0.isRead }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack {
                    
                }
                .frame(height: 50)
                VStack(spacing: 20) {
                    MatchStatusHeaderView(
                        state: matchState,
                        onPrepareMatch: { isSelectingField = true },
                        onForceEndMatch: {
                            sessionManager.requestForceEndMatch()
                        }
                    )
                    .padding(.horizontal, 24)
                    
                    OverallSummaryView(
                        stat: overallStat,
                        matchCount: overallHistory.workouts.count,
                        totalDistanceKm: overallHistory.totalDistanceKm,
                        avgCalories: overallHistory.averageCalories
                    )
                    .padding(.horizontal, 24)
                    
                    #if DEBUG
                    if usesMockData, let calculation = overallHistory.current {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("목업 데이터 · 임시 기준값 적용")
                            Text(String(format: "활동량 %.2f× · 속도 %.2f× · 가감속 %.2f×",
                                        calculation.activityRatio, calculation.speedRatio, calculation.changeRatio))
                        }
                        .font(.caption1M)
                        .foregroundStyle(.gray400)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    }
                    #endif

                    if !overallHistory.workouts.isEmpty {
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
                // FieldListView(운동장 선택/등록) → ReadyForMatchView("경기 준비" 확인) →
                // "준비하기" 눌렀을 때만 여기가 호출된다.
                FieldListView(onFieldPrepared: { field in
                    preparedField = field
                    isSelectingField = false
                    // 워치에 경기가 준비됐다고 알린다 — StartView가 대기 화면 대신
                    // "경기 시작" 버튼을 보여주게 된다.
                    sessionManager.updateMatchPrepared(fieldName: field.name)
                })
            }
            .onChange(of: sessionManager.isMatchInProgress) { _, isInProgress in
                if isInProgress {
                    preparedField = nil
                    // 경기가 시작되면 "준비됨" 신호를 꺼서, 다음 경기 전까지는 워치가
                    // 다시 대기 화면(Default 상태)을 보여주게 한다.
                    sessionManager.updateMatchPrepared(fieldName: nil)
                }
            }
            headerBar
        }
        .task { try? await UserSession.refreshProfile() }
        .task(id: overallSource) {
            let source = overallSource
            #if DEBUG
            if source.usesMockData {
                overallHistory = OverallCalculator.history(from: OverallMockData.workouts)
                return
            }
            #endif
            overallHistory = OverallCalculator.history(from: source.inputs.compactMap { $0.workout() })
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
            
            // 이슈 #42 "Remind" 댓글 — 안 읽은 알림이 있으면 벨 아이콘이 바뀐다.
            // sessionManager.notifications가 공용 저장소라서 경기 분석 결과가 도착하면
            // (SessionManager.didReceive(file:)) 바로 반영된다. DESIGN-GAP: "읽음 처리"
            // 자체는 아직 없어서 — 알림 화면에 들어갔다 나와도 안 바뀐다.
            NavigationLink(destination: NotificationListView()) {
                if hasUnreadNotifications {
                    // ic_bell_new는 민트색 점이 박힌 2톤 에셋이라(ic_goal/ic_assist와 같은
                    // 패턴) .renderingMode(.original)로 카탈로그의 template 설정을 덮어써야
                    // 점 색이 산다.
                    Image("ic_bell_new")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .glassCircleBackground()
                } else {
                    Image("ic_bell")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.colorTextPrimary)
                        .frame(width: 44, height: 44)
                        .glassCircleBackground()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
