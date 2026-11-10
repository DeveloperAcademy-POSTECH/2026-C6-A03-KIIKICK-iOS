//
//  ReadyForDetailView.swift
//  KIIKICK
//
//  Figma node 742:11705 "readyforDetail" (이슈 #43) — 경기 분석을 보기 전에 쿼터별
//  포지션/공격 방향(좌우반전)을 확인·수정하는 확인 화면. CardQuarterView를 쿼터 수만큼
//  반복한다.
//
//  분석 플로우: AnalysisView(목록) → ReadyForDetailView(여기) → AnalyzingView →
//  AnalysisDetailView → TimelineView. "분석 보기"를 누르면 포지션과 공격 방향을
//  로컬 기록에 저장하고, 운동장은 venues API에 저장한 뒤 workout-submissions를 보낸다.
//
//  이슈 #50: iOS에서 경기를 강제 종료하면 워치가 PositionView를 거치지 못해 쿼터의
//  포지션이 nil로 들어온다(AnalysisQuarter.position). 그런 쿼터는 "CM" 같은 값으로
//  조용히 채워 넣지 않고 "선택 필요" placeholder로 비워 두고, 사용자가 드롭다운에서
//  실제로 고르기 전까진 "분석 보기"를 막는다(isPositionConfirmed).
//

import OSLog
import SwiftUI
import SwiftData

struct ReadyForDetailView: View {
    private static let logger = Logger(subsystem: "KIIKICK", category: "WorkoutSubmission")

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    let entry: AnalysisEntry
    let navigationTab: AppRouter.AppTab
    @State private var positions: [String]
    @State private var flips: [Bool]
    @State private var isPositionConfirmed: [Bool]
    @State private var isPresentingPositionRequiredAlert = false
    @State private var isPresentingFieldPicker = false
    @State private var isPresentingFieldRequiredAlert = false
    @State private var fieldsByQuarterID: [UUID: Field]
    @State private var saveError: String?
    @State private var isSubmitting = false

    private static let unselectedPositionPlaceholder = "선택 필요"

    private var quarters: [AnalysisQuarter] { entry.detail.quarters }

    init(entry: AnalysisEntry, navigationTab: AppRouter.AppTab = .analysis) {
        self.entry = entry
        self.navigationTab = navigationTab
        _positions = State(initialValue: entry.detail.quarters.map { $0.position ?? Self.unselectedPositionPlaceholder })
        _flips = State(initialValue: entry.detail.quarters.map(\.isAttackDirectionReversed))
        _isPositionConfirmed = State(initialValue: entry.detail.quarters.map { $0.position != nil })
        var fields: [UUID: Field] = [:]
        for quarter in entry.detail.quarters {
            if let field = quarter.sourceRecord?.field ?? quarter.field {
                fields[quarter.id] = field
            }
        }
        _fieldsByQuarterID = State(initialValue: fields)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.dateAndQuarter)
                    .font(.head2SB)
                    .foregroundStyle(.colorTextPrimary)

                directionGuide

                if hasMissingFields {
                    fieldAssignmentNotice
                }

                ForEach(Array(quarters.enumerated()), id: \.element.id) { index, quarter in
                    CardQuarterView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        field: field(for: quarter),
                        points: quarter.points,
                        position: Binding(
                            get: { positions[index] },
                            set: { positions[index] = $0; isPositionConfirmed[index] = true }
                        ),
                        isFlipped: $flips[index],
                        positionChangeText: positionChangeText(index: index, original: quarter.position)
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("모든 쿼터의 설정을 한 번에 저장합니다.")
                        .font(.caption1M)
                        .foregroundStyle(.colorTextSecondary)
                    CtaView(
                        text: isSubmitting ? "업로드 중..." : "분석 보기",
                        type: .primary,
                        size: .large,
                        isActive: !hasMissingFields && !isSubmitting,
                        action: saveAndAnalyze
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
            ToolbarItem(placement: .principal) {
                Text("분석 준비")
                    .font(.head3B)
                    .foregroundStyle(.colorTextPrimary)
            }
        }
        .alert("설정을 저장하지 못했어요", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { } message: { Text(saveError ?? "") }
        .alert("포지션을 선택해주세요", isPresented: $isPresentingPositionRequiredAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("경기가 강제로 종료돼 포지션이 기록되지 않은 쿼터가 있어요. 분석을 보려면 모든 쿼터의 포지션을 선택해주세요.")
        }
        .alert("운동장을 지정해주세요", isPresented: $isPresentingFieldRequiredAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("운동장이 없는 쿼터가 있어요. 분석을 보려면 운동장을 지정해주세요.")
        }
        .navigationDestination(isPresented: $isPresentingFieldPicker) {
            FieldListView(onFieldSelected: assignMissingFields)
        }
    }

    private func saveAndAnalyze() {
        guard !isSubmitting else { return }
        guard !hasMissingFields else {
            isPresentingFieldRequiredAlert = true
            return
        }
        guard !isPositionConfirmed.contains(false) else {
            isPresentingPositionRequiredAlert = true
            return
        }
        let originals = quarters.map { ($0.sourceRecord?.position, $0.sourceRecord?.isAttackDirectionReversed ?? false) }
        for (index, quarter) in quarters.enumerated() {
            quarter.sourceRecord?.position = Position(rawValue: positions[index].lowercased())
            quarter.sourceRecord?.isAttackDirectionReversed = flips[index]
        }
        do {
            try modelContext.save()
            let updatedQuarters = quarters.enumerated().map { index, quarter in
                var updated = AnalysisQuarter(
                    id: quarter.id, quarterNumber: quarter.quarterNumber, durationText: quarter.durationText,
                    startDate: quarter.startDate, duration: quarter.duration,
                    position: positions[index], field: quarter.field, points: quarter.points, events: quarter.events,
                    totalDistanceKm: quarter.totalDistanceKm, totalCaloriesKcal: quarter.totalCaloriesKcal
                )
                updated.isAttackDirectionReversed = flips[index]
                updated.sourceRecord = quarter.sourceRecord
                return updated
            }
            let detail = entry.detail
            let updatedEntry = AnalysisEntry(
                id: entry.id, date: entry.date, dateAndQuarter: entry.dateAndQuarter,
                fieldName: quarters.first.flatMap(field(for:))?.name ?? entry.fieldName, stats: entry.stats,
                detail: AnalysisDetail(id: detail.id, title: detail.title, quarters: updatedQuarters,
                    keyStats: detail.keyStats, goalCount: detail.goalCount, assistCount: detail.assistCount,
                    sections: detail.sections, disclaimer: detail.disclaimer),
                records: entry.records
            )
            isSubmitting = true
            Task {
                defer { isSubmitting = false }
                do {
                    try await submitWorkouts()
                    for record in entry.records { record.hasViewedAnalysis = true }
                    try modelContext.save()
                    router.pushAnalysis(.analyzing(updatedEntry), in: navigationTab)
                } catch {
                    saveError = error.localizedDescription
                }
            }
        } catch {
            for (index, quarter) in quarters.enumerated() {
                quarter.sourceRecord?.position = originals[index].0
                quarter.sourceRecord?.isAttackDirectionReversed = originals[index].1
            }
            saveError = error.localizedDescription
        }
    }

    private var hasMissingFields: Bool {
        quarters.contains { field(for: $0) == nil }
    }

    private func field(for quarter: AnalysisQuarter) -> Field? {
        fieldsByQuarterID[quarter.id] ?? quarter.sourceRecord?.field ?? quarter.field
    }

    private var fieldAssignmentNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("운동장이 지정되지 않은 쿼터가 있어요")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text("운동장을 지정하면 히트맵과 분석 결과를 정확히 볼 수 있어요.")
                .font(.body4R)
                .foregroundStyle(.colorTextSecondary)
            CtaView(text: "운동장 지정하기", type: .secondary, size: .small) {
                isPresentingFieldPicker = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func assignMissingFields(_ field: Field) {
        let missingQuarters = quarters.filter { self.field(for: $0) == nil }
        let previousFields = missingQuarters.map { $0.sourceRecord?.field }
        for quarter in missingQuarters {
            quarter.sourceRecord?.field = field
            fieldsByQuarterID[quarter.id] = field
        }
        do {
            try modelContext.save()
        } catch {
            for (index, quarter) in missingQuarters.enumerated() {
                quarter.sourceRecord?.field = previousFields[index]
                if previousFields[index] == nil {
                    fieldsByQuarterID.removeValue(forKey: quarter.id)
                }
            }
            saveError = error.localizedDescription
        }
    }

    /// 완료 경기와 쿼터를 원자적으로 제출한 뒤에만 분석 상세로 진행한다.
    private func submitWorkouts() async throws {
        guard let firstRecord = entry.records.first else { throw NetworkError.emptyData }
        let matchId = firstRecord.matchId
        let repairedCount = try repairDuplicateQuarterIDs(in: entry.records)
        if repairedCount > 0 {
            Self.logger.debug("workout-submissions: 중복 quarterId \(repairedCount, privacy: .public)개를 새 UUID로 복구했습니다.")
        }
        try await ensureFieldsAreUploaded(for: entry.records)

        let quarters = zip(entry.records, positions).map { record, position in
            // 서버가 points/heartRateSamples/events의 timestamp가 startDate~endDate
            // 범위 안에 있는지 검증한다(422 "points[0].timestamp"로 확인됨) — 워치에서
            // 첫 GPS 포인트가 공식 시작 시각(record.date)보다 살짝 먼저 버퍼링되는
            // 타이밍 특성 때문에 record.date/duration만 쓰면 범위를 벗어난다. 실제
            // 샘플들의 최소/최대로 넓혀서 전부 범위 안에 들어오게 한다(데이터는 안 버림).
            let allTimestamps = record.points.map(\.timestamp)
                + record.heartRateSamples.map(\.timestamp)
                + record.events.map(\.location.timestamp)
            let startDate = ([record.date] + allTimestamps).min()!
            let endDate = ([record.date.addingTimeInterval(record.duration)] + allTimestamps).max()!
            return SubmissionQuarter(
                quarterId: record.quarterId.uuidString.lowercased(),
                position: position.uppercased(),
                workout: WorkoutPayload(
                    startDate: startDate,
                    endDate: endDate,
                    points: record.points,
                    heartRateSamples: record.heartRateSamples,
                    totalCalories: record.totalCalories,
                    totalDistance: record.totalDistance,
                    events: record.events,
                    field: Self.workoutFieldPayload(for: record.field)
                )
            )
        }
        // If-Match: 제출 직전에 최신 경기 version을 조회해서 그대로 넘긴다. 조회가
        // 실패하면(서버에 아직 등록 안 된 경기 — 지금 이 디버깅 플로우에서는 보통 이쪽)
        // 버전을 모른다는 뜻이라 헤더 자체를 생략한다(submit의 ifMatch: nil).
        if firstRecord.submissionIdempotencyKey == nil {
            do {
                let detail = try await NetworkService.provider.request(
                    with: MatchEndpoints.detail(matchId: matchId))
                firstRecord.submissionIfMatch = String(detail.data.version)
            } catch NetworkError.invalidHttpStatusCode(404, _) {
                firstRecord.submissionIfMatch = nil
            } catch {
                throw error
            }
            firstRecord.submissionIdempotencyKey = UUID()
            try modelContext.save()
        }
        let ifMatch = firstRecord.submissionIfMatch
        let requestSummary = Self.requestSummary(matchId: matchId, ifMatch: ifMatch, quarters: quarters)
        Self.logger.debug("workout-submissions 요청: \(requestSummary, privacy: .public)")
        let result: MatchResultEnvelope<SubmissionReceipt> = try await NetworkService.provider.request(
            with: QuarterWorkoutEndpoints.submit(matchId: matchId, quarters: quarters,
                ifMatch: ifMatch, idempotencyKey: firstRecord.submissionIdempotencyKey)
        )
        Self.logger.debug("workout-submissions 성공: \(String(describing: result.data), privacy: .public)")
    }

    /// 과거 앱 버전에서 같은 UUID로 저장된 여러 쿼터는 서버가 하나의 제출로 처리할 수
    /// 없다. 아직 서버에 저장되지 않은 로컬 기록이므로 두 번째 항목부터 새 ID로 바꿔
    /// 이후 재시도에도 같은 ID를 사용한다.
    private func repairDuplicateQuarterIDs(in records: [WorkoutRecord]) throws -> Int {
        var seen = Set<UUID>()
        var repairedCount = 0

        for record in records {
            guard !seen.insert(record.quarterId).inserted else { continue }
            var replacement = UUID()
            while !seen.insert(replacement).inserted {
                replacement = UUID()
            }
            record.quarterId = replacement
            repairedCount += 1
        }

        if repairedCount > 0 {
            try modelContext.save()
        }
        return repairedCount
    }

    /// 새 UI가 생기기 전에 로컬에만 저장된 운동장도 분석 제출 전에 venues API에
    /// 등록한다. 새 경기장 생성은 FieldNamingView에서 즉시 등록하지만, 이 보정 경로는
    /// 기존 목록에서 선택한 운동장까지 보장한다.
    private func ensureFieldsAreUploaded(for records: [WorkoutRecord]) async throws {
        var uploaded: [Field] = []
        for field in records.compactMap(\.field) {
            guard !uploaded.contains(where: { $0 === field }) else { continue }
            try await VenueStore.ensureUploaded(field, context: modelContext)
            uploaded.append(field)
        }
    }

    /// 팝업에 전체 JSON(특히 points/heartRateSamples)을 그대로 넣으면 너무 길어서, 핵심
    /// 필드만 뽑은 요약이다. 전체 원문은 Self.prettyPrintedJSON으로 콘솔에 남긴다.
    private static func requestSummary(matchId: UUID, ifMatch: String?, quarters: [SubmissionQuarter]) -> String {
        var lines = ["[보낸 요청]", "matchId: \(matchId)", "If-Match: \(ifMatch ?? "(생략)")"]
        for (index, quarter) in quarters.enumerated() {
            lines.append(
                "쿼터[\(index)] quarterId=\(quarter.quarterId) position=\(quarter.position) " +
                "points=\(quarter.workout.points.count) hr=\(quarter.workout.heartRateSamples.count) " +
                "field=\(quarter.workout.field?.name ?? "nil")"
            )
        }
        return lines.joined(separator: "\n")
    }

    private static func prettyPrintedJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value), let text = String(data: data, encoding: .utf8) else {
            return "(인코딩 실패)"
        }
        return text
    }

    /// 이슈 #66: WorkoutFieldRequest(cornerA-D 필수, name 필수)를 채운다 — 운동장이
    /// 미지정이면(record.field == nil) nil을 그대로 둔다. 서버가 그 경우까지 받아줄지는
    /// 확인 안 됐다.
    private static func workoutFieldPayload(for field: Field?) -> WorkoutFieldPayload? {
        guard let field else { return nil }
        func corner(_ c: FieldCorner) -> WorkoutFieldPayload.Corner {
            WorkoutFieldPayload.Corner(latitude: c.latitude, longitude: c.longitude)
        }
        return WorkoutFieldPayload(
            name: field.name,
            cornerA: corner(field.cornerA), cornerB: corner(field.cornerB),
            cornerC: corner(field.cornerC), cornerD: corner(field.cornerD),
            rawCornerA: field.rawCornerA.map(corner), rawCornerB: field.rawCornerB.map(corner),
            rawCornerC: field.rawCornerC.map(corner), rawCornerD: field.rawCornerD.map(corner)
        )
    }

    private func positionChangeText(index: Int, original: String?) -> String? {
        guard let original else { return nil }
        return positions[index] == original ? nil : "\(original) → \(positions[index])"
    }

    private var directionGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("공격 방향은 오른쪽으로 맞춰주세요")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text("실제 공격 방향과 다르면 맵을 180° 회전하세요")
                .font(.body4R)
                .foregroundStyle(.colorTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ReadyForDetailView(entry: .previewSample)
    }
    .environment(AppRouter())
}
#endif
