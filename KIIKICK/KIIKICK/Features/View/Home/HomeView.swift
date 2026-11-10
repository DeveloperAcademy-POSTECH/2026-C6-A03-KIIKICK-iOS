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
//  저장된 WorkoutRecord의 속도 샘플로 누적 OVR을 계산한다.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    
    @State private var preparedField: Field?
    @State private var isSelectingField = false
    @State private var selectedMetric: PerformanceMetric = .overall
    
    @State private var overallHistory: OverallHistory = .empty

    private var overallInputs: [OverallWorkoutInput] {
        records.map(OverallWorkoutInput.init(record:))
    }

    private var overallStat: OverallStat {
        OverallStat(score: overallHistory.current?.score, delta: overallHistory.delta)
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
                // FieldListView(운동장 선택/등록) → ReadyForMatchView("경기 준비" 확인) →
                // "준비하기" 눌렀을 때만 여기가 호출된다.
                FieldListView(onFieldPrepared: { field in
                    preparedField = field
                    isSelectingField = false
                    // 워치에 경기가 준비됐다고 알린다 — StartView가 대기 화면 대신
                    // "경기 시작" 버튼을 보여주게 된다. sessionManager가 Field 참조도
                    // 들고 있다가(이슈 #66) 쿼터가 도착하면 WorkoutRecord.field로 이어준다.
                    sessionManager.updateMatchPrepared(field: field)
                })
            }
            .onChange(of: sessionManager.isMatchInProgress) { _, isInProgress in
                if isInProgress {
                    preparedField = nil
                    // 경기가 시작되면 "준비됨" 표시만 꺼서, 다음 경기 전까지는 워치가
                    // 다시 대기 화면(Default 상태)을 보여주게 한다. sessionManager의
                    // Field 참조는 그대로 둔다 — 쿼터들이 경기 진행 중에 도착한다.
                    sessionManager.clearPreparedFieldDisplay()
                }
            }
            headerBar
        }
        .task {
            // 이슈 #63: 홈 화면 진입도 재인증 트리거다 — accessToken이 앱이 떠 있는 동안
            // 만료됐으면 여기서 refreshToken으로 재인증한다. refreshToken도 무효면
            // 로그인 화면으로 돌려보낸다.
            guard await UserSession.reauthenticateIfNeeded() else {
                router.didLogOut()
                return
            }
            try? await UserSession.refreshProfile()
        }
        .task(id: overallInputs) {
            overallHistory = OverallCalculator.history(from: overallInputs.compactMap { $0.workout() })
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
            // (SessionManager.didReceive(file:)) 바로 반영된다. 분석/댓글 셀 진입 시 로컬 읽음
            // 상태를 갱신한다. 서버 읽음 상태 동기화·영속화는 별도 작업이다.
            Button { router.showNotifications(in: .home) } label: {
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
