//
//  AnalysisDetailView.swift
//  KIIKICK
//
//  Figma node 367:1711 "detail" / 735:11387 "detail"(이슈 #43 갱신본) — 이슈 #43에서
//  "분석"/"댓글" 세그먼트 컨트롤을 없애고, 댓글은 화면 아래 항상 떠 있는 바텀시트로
//  바꿨다(접힌 상태에서도 "댓글 N" 헤더가 보이고, 끌어올리면 전체 목록이 보임).
//  히트맵 위에는 "타임라인 보기" 버튼을 추가해 TimelineView로 넘어간다.
//  node 735:11387의 toolbar는 뒤로가기 + 제목 + 우측 상단 공유 버튼 하나뿐이라
//  기존 ellipsis 메뉴(공유하기/삭제하기)를 없애고 공유 버튼만 남겼다. "삭제하기"는
//  Figma에서도 툴바가 아니라 본문 하단에 별도 버튼으로 있어서 그 자리로 옮겼다.
//  우측 상단 공유 버튼은 ShareImageView(node 750:5505/750:5684, 이미지로 내보내서
//  사진 앱에 저장)로 연결된다. 기존에 본문에 있던 "내 플레이 공유하기" 버튼은
//  삭제하고 그 자리에 "Key Stats" 제목(node 742:11966, 버튼 아님)을 넣었다.
//

import SwiftUI
import SwiftData

struct AnalysisDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let entry: AnalysisEntry
    let friendNickname: String?
    let friendUserID: UUID?
    let friendMatchID: UUID?
    @State private var commentsModel: MatchCommentsModel

    @State private var selectedQuarterIndex = 0
    @State private var pushedFriendsPlayedTogether = false
    @State private var quarterFriendModels: [UUID: QuarterFriendsModel] = [:]
    @State private var friendHeatmapModels: [UUID: FriendHeatmapModel] = [:]
    @State private var pushedTimeline = false
    @State private var pushedShare = false
    @State private var commentSheetDetent: PresentationDetent
    // 이슈 #96: 분석을 한 번 본 경기는 분석 준비 화면을 다시 거치지 않으므로, 운동장
    // 수정은 이 화면에서도 가능해야 한다.
    @State private var assignment: FieldAssignment
    @State private var pendingField: Field?
    @State private var isPresentingFieldPicker = false
    @State private var fieldError: String?
    @State private var isSyncingField = false
    @State private var isResubmitting = false
    @State private var resubmitReport: SubmissionDebugReport?
    @State private var fieldSyncError: String?

    init(
        entry: AnalysisEntry,
        friendNickname: String? = nil,
        matchID: UUID? = nil,
        friendUserID: UUID? = nil,
        showComments: Bool = false
    ) {
        self.entry = entry
        self.friendNickname = friendNickname
        self.friendUserID = friendUserID
        friendMatchID = matchID
        _commentsModel = State(initialValue: MatchCommentsModel(matchID: matchID ?? entry.records.first?.matchId ?? entry.id))
        _commentSheetDetent = State(initialValue: showComments ? .large : .height(70))
        _assignment = State(initialValue: FieldAssignment(
            quarters: entry.detail.quarters.map {
                FieldAssignment.QuarterInput(id: $0.id, record: $0.sourceRecord, field: $0.field)
            }
        ))
    }

    /// 이슈 #96: 운동장 변경이 하위 뷰(TimelineView 등)까지 전해지도록, 오버레이를
    /// 반영한 쿼터를 한 번 만들어 화면 전체가 같은 값을 쓰게 한다.
    private var displayQuarters: [AnalysisQuarter] { assignment.applying(to: entry.detail.quarters) }

    private var displayDetail: AnalysisDetail {
        let detail = entry.detail
        return AnalysisDetail(
            id: detail.id, title: detail.title, quarters: displayQuarters,
            keyStats: detail.keyStats, goalCount: detail.goalCount, assistCount: detail.assistCount,
            sections: detail.sections, disclaimer: detail.disclaimer
        )
    }

    private var currentQuarter: AnalysisQuarter? {
        let quarters = displayQuarters
        guard quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return quarters[selectedQuarterIndex]
    }

    private var ownerMatchID: UUID? {
        entry.records.first?.matchId ?? (friendNickname == nil ? entry.id : nil)
    }

    private var currentQuarterID: UUID? {
        currentQuarter?.sourceRecord?.quarterId ?? currentQuarter?.id
    }

    private var currentQuarterFriendModel: QuarterFriendsModel? {
        guard let currentQuarterID else { return nil }
        return quarterFriendModels[currentQuarterID]
    }

    private var currentFriendHeatmapModel: FriendHeatmapModel? {
        guard let quarterID = currentQuarter?.id else { return nil }
        return friendHeatmapModels[quarterID]
    }

    var body: some View {
        AnalysisTabContent(
            detail: displayDetail,
            isOwner: friendNickname == nil,
            selectedQuarterIndex: $selectedQuarterIndex,
            friendsCount: currentQuarterFriendModel?.friends.count ?? 0,
            canManageFriends: ownerMatchID != nil && currentQuarterID != nil,
            friendHeatmapModel: currentFriendHeatmapModel,
            onChangeField: (friendNickname == nil && assignment.isEditable)
                ? { isPresentingFieldPicker = true } : nil,
            isSyncingField: isSyncingField,
            onResubmit: resubmitAction,
            isResubmitting: isResubmitting,
            onShowFriends: {
                guard ensureCurrentQuarterFriendModel() != nil else { return }
                pushedFriendsPlayedTogether = true
            },
            onShowTimeline: { pushedTimeline = true }
        )
        .background(Color.gray950)
        // DESIGN-GAP: 친구 상세 헤더는 기존 제목 영역에 닉네임·날짜를 함께 표시한다.
        .navigationTitle(friendNickname.map { "\($0) · \(entry.detail.title)" } ?? entry.detail.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if friendNickname == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { pushedShare = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.gray50)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $pushedFriendsPlayedTogether) {
            if let currentQuarterFriendModel {
                FriendsPlayedTogetherView(model: currentQuarterFriendModel)
            }
        }
        .navigationDestination(isPresented: $pushedTimeline) {
            if let currentQuarter {
                TimelineView(dateTitle: entry.detail.title, quarter: currentQuarter)
            }
        }
        .navigationDestination(isPresented: $pushedShare) {
            ShareImageView(keyStats: entry.detail.keyStats)
        }
        .navigationDestination(isPresented: $isPresentingFieldPicker) {
            FieldListView(onFieldSelected: handlePickedField)
        }
        .confirmationDialog("이 운동장을 어디에 적용할까요?", isPresented: Binding(
            get: { pendingField != nil }, set: { if !$0 { pendingField = nil } }
        ), titleVisibility: .visible) {
            Button("모든 쿼터에 적용") { applyPendingField(to: .allQuarters) }
            if let quarterID = currentQuarter?.id {
                Button("이 쿼터만") { applyPendingField(to: .quarter(quarterID)) }
            }
            Button("취소", role: .cancel) { pendingField = nil }
        }
        .alert("운동장을 바꾸지 못했어요", isPresented: Binding(
            get: { fieldError != nil }, set: { if !$0 { fieldError = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(fieldError ?? "")
        }
        .overlay {
            if let resubmitReport {
                SubmissionDebugPopup(report: resubmitReport) { self.resubmitReport = nil }
            }
        }
        .alert("서버에 반영하지 못했어요", isPresented: Binding(
            get: { fieldSyncError != nil }, set: { if !$0 { fieldSyncError = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("운동장은 이 기기에 저장됐어요. 네트워크가 돌아오면 다시 시도해주세요.\n\(fieldSyncError ?? "")")
        }
        .onAppear {
            guard friendNickname == nil, entry.records.contains(where: { !$0.hasViewedAnalysis }) else { return }
            for record in entry.records { record.hasViewedAnalysis = true }
            try? modelContext.save()
        }
        // 댓글은 세그먼트 전환이 아니라, 화면 아래 항상 떠 있는 바텀시트로 보여준다
        // (Figma "sheet/collapsed", node 735:11489) — 접힌 상태에서도 "댓글 N" 헤더가
        // 보이고 끌어올리면 전체 목록이 보인다. 닫을 수 없는 permanent 시트라
        // isPresented를 상수 true로 고정했다.
        .sheet(isPresented: .constant(true)) {
            MatchCommentsSheet(model: commentsModel, isExpanded: commentSheetDetent == .large)
            .presentationDetents([.height(70), .large], selection: $commentSheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(Color.gray900)
            .interactiveDismissDisabled()
        }
        .task(id: currentQuarterID) {
            guard friendNickname == nil, let model = ensureCurrentQuarterFriendModel() else { return }
            await model.loadIfNeeded()
        }
        .task(id: currentQuarter?.id) {
            guard let model = ensureCurrentFriendHeatmapModel() else { return }
            await model.loadIfNeeded()
        }
    }

    /// 큰 뷰 표현식 안에서 삼항 연산자로 클로저를 만들면 타입 추론이 터져서 따로 뺐다.
    private var resubmitAction: (() -> Void)? {
        canResubmit ? { resubmitAnalysis() } : nil
    }

    /// 이슈 #96: 이미 서버로 보낸 적 있는 내 경기만 다시 보낼 수 있다.
    private var canResubmit: Bool {
        friendNickname == nil && entry.records.contains { $0.submissionIdempotencyKey != nil }
    }

    /// "분석 보기"와 같은 workout-submissions 경로를 재전송 모드로 부른다 — 새
    /// Idempotency-Key와 최신 If-Match를 써서, 바뀐 운동장·포지션이 서버에 반영되게 한다.
    private func resubmitAnalysis() {
        guard !isResubmitting else { return }
        let quarters = entry.detail.quarters
        let records = quarters.compactMap(\.sourceRecord)
        let positions = quarters.compactMap { $0.position?.uppercased() }
        guard records.count == quarters.count, positions.count == quarters.count, !records.isEmpty else {
            resubmitReport = SubmissionDebugReport(
                title: "분석 다시 보내기",
                lines: ["보내지 않았습니다 — 포지션이 비어 있는 쿼터가 있어요(서버는 position이 필수입니다)."]
            )
            return
        }
        isResubmitting = true
        // 요청 요약과 응답을 그대로 모아 팝업에 띄운다 — 서버가 재전송을 갱신으로
        // 처리하는지 확인하려면 상태 코드와 quarterCount를 봐야 한다(이슈 #96).
        var lines: [String] = []
        Task {
            defer { isResubmitting = false }
            do {
                try await WorkoutSubmissionStore.submit(
                    records: records, positions: positions,
                    mode: .resubmission, context: modelContext,
                    debug: { lines.append($0) }
                )
            } catch {
                lines.append("[오류] \(error)")
            }
            resubmitReport = SubmissionDebugReport(title: "분석 다시 보내기", lines: lines)
        }
    }

    /// 쿼터가 하나뿐이면 적용 범위를 물을 필요가 없다.
    private func handlePickedField(_ field: Field) {
        guard entry.detail.quarters.count > 1 else {
            applyField(field, to: .allQuarters)
            return
        }
        pendingField = field
    }

    private func applyPendingField(to scope: FieldAssignmentScope) {
        guard let field = pendingField else { return }
        pendingField = nil
        applyField(field, to: scope)
    }

    /// 로컬 저장이 먼저고, 서버 반영은 실패해도 로컬 수정을 되돌리지 않는다 —
    /// 히트맵은 로컬 값으로 그리므로 화면은 이미 맞다.
    private func applyField(_ field: Field, to scope: FieldAssignmentScope) {
        do {
            try assignment.apply(field, to: scope, save: { try modelContext.save() })
        } catch {
            fieldError = error.localizedDescription
            return
        }
        let targets = assignment.targetQuarterIDs(for: scope)
        let quarters = targets.compactMap { id in entry.detail.quarters.first { $0.id == id } }
        let records = quarters.compactMap(\.sourceRecord)
        let positions = quarters.compactMap { $0.position?.uppercased() }
        guard records.count == quarters.count, positions.count == quarters.count, !records.isEmpty else { return }
        isSyncingField = true
        Task {
            defer { isSyncingField = false }
            do {
                _ = try await FieldServerSync.sync(
                    records: records, positions: positions, field: field, context: modelContext)
            } catch {
                fieldSyncError = error.localizedDescription
            }
        }
    }

    @MainActor
    private func ensureCurrentQuarterFriendModel() -> QuarterFriendsModel? {
        guard let matchID = ownerMatchID, let quarterID = currentQuarterID else { return nil }
        if let model = quarterFriendModels[quarterID] { return model }
        let model = QuarterFriendsModel(matchID: matchID, quarterID: quarterID)
        quarterFriendModels[quarterID] = model
        return model
    }

    @MainActor
    private func ensureCurrentFriendHeatmapModel() -> FriendHeatmapModel? {
        guard let userID = friendUserID,
              let matchID = friendMatchID,
              let quarterID = currentQuarter?.id else { return nil }
        if let model = friendHeatmapModels[quarterID] { return model }
        let model = FriendHeatmapModel(userID: userID, matchID: matchID, quarterID: quarterID)
        friendHeatmapModels[quarterID] = model
        return model
    }
}

private struct AnalysisTabContent: View {
    let detail: AnalysisDetail
    let isOwner: Bool
    @Binding var selectedQuarterIndex: Int
    let friendsCount: Int
    let canManageFriends: Bool
    let friendHeatmapModel: FriendHeatmapModel?
    /// 로컬 기록이 없는(서버 복원) 엔트리나 친구 경기는 nil — 변경 행을 숨긴다.
    var onChangeField: (() -> Void)?
    let isSyncingField: Bool
    /// 이슈 #96: 이미 제출된 내 경기에서만 재전송을 노출한다.
    var onResubmit: (() -> Void)?
    let isResubmitting: Bool
    var onShowFriends: () -> Void
    var onShowTimeline: () -> Void

    private var currentQuarter: AnalysisQuarter? {
        guard detail.quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return detail.quarters[selectedQuarterIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isOwner {
                    Button(action: onShowFriends) {
                        HStack(spacing: 4) {
                            Text("함께 뛴 친구 \(friendsCount)명")
                                .font(.body4R)
                                .foregroundStyle(.colorTextPrimary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.mint500)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .disabled(!canManageFriends)
                    .opacity(canManageFriends ? 1 : 0.5)

                }

                if let quarter = currentQuarter {
                    QuarterSelectorView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        canGoPrevious: selectedQuarterIndex > 0,
                        canGoNext: selectedQuarterIndex < detail.quarters.count - 1,
                        onPrevious: { selectedQuarterIndex = max(0, selectedQuarterIndex - 1) },
                        onNext: { selectedQuarterIndex = min(detail.quarters.count - 1, selectedQuarterIndex + 1) }
                    )
                    .frame(maxWidth: .infinity)

                    if let position = quarter.position {
                        positionRow(position)
                    }
                    if let onChangeField {
                        HStack(spacing: 8) {
                            FieldChangeRow(field: quarter.field, action: onChangeField)
                            if isSyncingField { ProgressView().tint(.mint500) }
                        }
                        .disabled(isSyncingField)
                    }
                    heatmapCarousel(quarter, friendHeatmapModel: friendHeatmapModel)
                }

                if isOwner {
                    Text("히트맵과 포지션이 정확한지 확인해주세요")
                        .font(.caption1M)
                        .foregroundStyle(.gray500)
                        .frame(maxWidth: .infinity, alignment: .center)

                }

                // node 742:11966 — "내 플레이 공유하기" 버튼이 있던 자리에 이제 "Key Stats"
                // 제목이 들어간다(버튼이 아니라 그냥 텍스트). head1B(28pt Bold) + 단색
                // mint500(#00DAC3), gradientForeground 아님.
                Text("Key Stats")
                    .font(.head1B)
                    .foregroundStyle(.mint500)
                    .frame(maxWidth: .infinity, alignment: .center)

                keyStatsSection
                goalAssistSection

                ForEach(currentQuarter?.resultSections ?? detail.sections) { section in
                    sectionView(section)
                }

                if let onResubmit {
                    CtaView(
                        text: isResubmitting ? "다시 보내는 중..." : "분석 다시 보기",
                        type: .secondary,
                        size: .large,
                        isActive: !isResubmitting,
                        action: onResubmit
                    )
                }

                if isOwner { CtaView(text: "삭제하기", type: .destructive, size: .large) { } }

                // 바텀시트가 접혀 있어도 마지막 섹션이 가리지 않게 여유 공간을 둔다.
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        // 댓글 시트가 .presentationBackgroundInteraction(.enabled)이라 시트 뒤
        // 본문도 탭할 수 있다 — 여기를 눌러도 키보드가 내려가야 한다.
        .dismissKeyboardOnTap()
    }

    private func positionRow(_ position: String) -> some View {
        HStack {
            Text(position)
                .font(.label2SB)
                .foregroundStyle(.gray50)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray850, in: Capsule())
            Spacer()
        }
    }

    /// 운동장이 있으면 히트맵/스프린트 두 페이지(WorkoutDetailView와 같은 구성)를, 없으면
    /// 빈 자리를 보여준다.
    private func heatmapCarousel(_ quarter: AnalysisQuarter, friendHeatmapModel: FriendHeatmapModel?) -> some View {
        Group {
            if isOwner {
                TrackingMapPager(field: quarter.field, points: quarter.points,
                                 isAttackDirectionReversed: quarter.isAttackDirectionReversed)
                .frame(height: 248)
                .overlay(alignment: .bottomTrailing) {
                    Button(action: onShowTimeline) {
                        HStack(spacing: 0) {
                            Text("타임라인 보기")
                                .font(.caption1M)
                                .foregroundStyle(.colorTextPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.colorTextPrimary)
                        }
                        .padding(.leading, 12)
                        .padding(.trailing, 8)
                        .padding(.vertical, 8)
                        .background(Color.colorSurfacePrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }
            } else {
                friendHeatmap(quarter, model: friendHeatmapModel)
            }
        }
    }

    @ViewBuilder
    private func friendHeatmap(_ quarter: AnalysisQuarter, model: FriendHeatmapModel?) -> some View {
        if let model {
            if model.isLoading && model.heatmap == nil {
                ProgressView("히트맵을 불러오는 중...")
                    .tint(.mint500)
                    .frame(maxWidth: .infinity, minHeight: 248)
            } else if let heatmap = model.heatmap, heatmap.status == .ready, !heatmap.cells.isEmpty,
                      quarter.field != nil {
                FriendHeatmapView(
                    field: quarter.field,
                    heatmap: heatmap,
                    isAttackDirectionReversed: quarter.isAttackDirectionReversed
                )
                .frame(height: 248)
                .accessibilityLabel("친구 히트맵, 표본 \(heatmap.sampleCount)개")
            } else {
                friendHeatmapMessage(heatmap: model.heatmap,
                    errorMessage: model.heatmap?.status == .ready && quarter.field == nil
                        ? "경기장 좌표를 불러올 수 없어요" : model.errorMessage, onRetry: {
                    Task { await model.reload() }
                })
            }
        } else {
            friendHeatmapMessage(heatmap: nil, errorMessage: nil, onRetry: {})
        }
    }

    private func friendHeatmapMessage(
        heatmap: FriendHeatmapResponse?,
        errorMessage: String?,
        onRetry: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 12) {
            Text(errorMessage ?? {
                switch heatmap?.status {
                case .noValidPoints: return "표시할 위치 데이터가 없어요"
                case .missingWorkout: return "이 쿼터의 기록을 찾을 수 없어요"
                default: return "친구의 히트맵을 준비하고 있어요"
                }
            }())
            .textStyle(.body4R)
            .foregroundStyle(.colorTextSecondary)
            if errorMessage != nil {
                Button("다시 불러오기", action: onRetry)
                    .font(.label4SB)
                    .foregroundStyle(.mint500)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 248)
        .background(Color.gray850, in: RoundedRectangle(cornerRadius: 4))
    }

    private var keyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 28) {
                ForEach(currentQuarter?.resultStats ?? detail.keyStats, id: \.label) { stat in
                    VStack(spacing: 12) {
                        Text(stat.label)
                            .font(.title4SB)
                            .foregroundStyle(.gray50)
                        VStack(spacing: 0) {
                            Text(stat.value)
                                .font(.display3SB)
                                .foregroundStyle(.gray50)
                            Text(stat.unit)
                                .font(.body4R)
                                .foregroundStyle(.gray400)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var goalAssistSection: some View {
        HStack(spacing: 24) {
            statBadge(.goal, count: isOwner ? detail.goalCount : currentQuarter?.resultGoals)
            statBadge(.assist, count: isOwner ? detail.assistCount : currentQuarter?.resultAssists)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statBadge(_ type: MatchEventType, count: Int?) -> some View {
        VStack(spacing: 4) {
            Text(type.name)
                .font(.label3M)
            ZStack {
                type.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
                Text(count.map(String.init) ?? "—")
                    .font(.display2SB)
                    .padding(.bottom, 40)
            }
        }
    }

    private func sectionView(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.head2SB)
            
            VStack(spacing: 0) {
                ForEach(section.rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.body4R)
                            .foregroundStyle(.gray400)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(row.value)
                                .font(.body1M)
                                .foregroundStyle(.gray50)
                            Text(row.unit)
                                .font(.body3R)
                                .foregroundStyle(.gray400)
                        }
                    }
                    .padding(.vertical, 12)
                    
                    if row != section.rows.last {
                        Rectangle()
                            .fill(Color.gray850)
                            .frame(height: 1)
                    }
                }
            }
            .padding(16)
            .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AnalysisDetailView(entry: .previewSample)
    }
}
#endif
