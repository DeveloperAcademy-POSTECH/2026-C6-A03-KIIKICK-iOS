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
    @Environment(AppRouter.self) private var router
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]
    
    @State private var preparedField: Field?
    @State private var isSelectingField = false
    @State private var selectedMetric: PerformanceMetric = .overall
    
    @State private var remoteMatches: [HomeSyncedMatch]?
    @State private var isSyncing = false
    @State private var didAuthenticate = false

    private var localGroups: [[WorkoutRecord]] {
        WorkoutMatchGrouping.groups(from: records)
    }

    /// 로컬에 있는 경기는 로컬 값을 사용하고, 다른 기기에서 올린 경기만 서버 값으로 보탠다.
    private var additionalRemoteMatches: [HomeSyncedMatch] {
        let localIDs = Set(localGroups.compactMap { $0.first?.matchId })
        return (remoteMatches ?? []).filter { $0.status == .completed && !localIDs.contains($0.id) }
    }

    private var overallHistory: OverallHistory {
        let local = records.compactMap { OverallWorkoutInput(record: $0).workout() }
        let remote = additionalRemoteMatches.flatMap(\.workouts)
        return OverallCalculator.history(from: local + remote)
    }

    private var matchCount: Int {
        localGroups.count + additionalRemoteMatches.count
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
        if records.isEmpty && matchCount == 0 {
            return .noRecords
        }
        return .idle
    }
    
    private var totalDistanceKm: Double {
        (records.reduce(0) { $0 + $1.totalDistance }
            + additionalRemoteMatches.reduce(0) { $0 + $1.totalDistanceMeters }) / 1000
    }

    private var avgCalories: Int {
        let remoteQuarters = additionalRemoteMatches.reduce(0) { $0 + $1.quarterCount }
        let count = records.count + remoteQuarters
        guard count > 0 else { return 0 }
        let total = records.reduce(0) { $0 + $1.totalCalories }
            + additionalRemoteMatches.reduce(0) { $0 + $1.totalCalories }
        return Int(total / Double(count))
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

    private var trendAxisValues: [Double] {
        let maximum = trendPoints.map(\.value).max() ?? 0
        let ceiling = max(1, (maximum / 4).rounded(.up)) * 4
        return (0...4).map { Double($0) * ceiling / 4 }
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
                        matchCount: matchCount,
                        totalDistanceKm: totalDistanceKm,
                        avgCalories: avgCalories
                    )
                    .padding(.horizontal, 24)
                    
                    if matchCount > 0 {
                        PerformanceTrendsView(
                            selectedMetric: $selectedMetric,
                            points: trendPoints,
                            unit: trendUnit,
                            dateLabel: overallHistory.workouts.last?.date.formatted(date: .abbreviated, time: .omitted) ?? "",
                            yAxisValues: trendAxisValues
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
            didAuthenticate = true
            try? await UserSession.refreshProfile()
            await synchronizeMatches()
        }
        .onAppear {
            Task { await synchronizeMatches() }
        }
        .onChange(of: records) { _, _ in
            Task { await synchronizeMatches() }
        }
    }

    private func synchronizeMatches() async {
        guard didAuthenticate, !isSyncing, UserSession.token != nil else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let ownerID = UserSession.userId
            let result = try await HomeMatchSync.load()
            guard UserSession.userId == ownerID else { return }
            remoteMatches = result
        } catch {
            // 네트워크 오류 중에는 SwiftData의 기록을 그대로 보여준다.
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
