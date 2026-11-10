//
//  ReadyForDetailView.swift
//  KIIKICK
//
//  Figma node 742:11705 "readyforDetail" (이슈 #43) — 경기 분석을 보기 전에 쿼터별
//  포지션/공격 방향(좌우반전)을 확인·수정하는 확인 화면. CardQuarterView를 쿼터 수만큼
//  반복한다.
//
//  분석 플로우: AnalysisView(목록) → ReadyForDetailView(여기) → AnalyzingView →
//  AnalysisDetailView → TimelineView. 실제 분석 API가 아직 없어서 "분석 보기"를
//  누르면 포지션과 공격 방향을 로컬 기록에 저장하고 수정한 분석 데이터를 넘긴다.
//  서버 저장 API 연동은 범위 밖.
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
    @State private var positions: [String]
    @State private var flips: [Bool]
    @State private var isPositionConfirmed: [Bool]
    @State private var isPresentingPositionRequiredAlert = false
    @State private var saveError: String?

    private static let unselectedPositionPlaceholder = "선택 필요"

    private var quarters: [AnalysisQuarter] { entry.detail.quarters }

    init(entry: AnalysisEntry) {
        self.entry = entry
        _positions = State(initialValue: entry.detail.quarters.map { $0.position ?? Self.unselectedPositionPlaceholder })
        _flips = State(initialValue: entry.detail.quarters.map(\.isAttackDirectionReversed))
        _isPositionConfirmed = State(initialValue: entry.detail.quarters.map { $0.position != nil })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.dateAndQuarter)
                    .font(.head2SB)
                    .foregroundStyle(.colorTextPrimary)

                directionGuide

                ForEach(Array(quarters.enumerated()), id: \.element.id) { index, quarter in
                    CardQuarterView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        field: quarter.field,
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
                    CtaView(text: "분석 보기", type: .primary, size: .large, action: saveAndAnalyze)
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
    }

    private func saveAndAnalyze() {
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
                fieldName: entry.fieldName, stats: entry.stats,
                detail: AnalysisDetail(id: detail.id, title: detail.title, quarters: updatedQuarters,
                    keyStats: detail.keyStats, goalCount: detail.goalCount, assistCount: detail.assistCount,
                    sections: detail.sections, disclaimer: detail.disclaimer),
                records: entry.records
            )
            Task { await submitWorkouts() }
            router.paths[.analysis, default: .init()].append(AnalysisRoute.analyzing(updatedEntry))
        } catch {
            for (index, quarter) in quarters.enumerated() {
                quarter.sourceRecord?.position = originals[index].0
                quarter.sourceRecord?.isAttackDirectionReversed = originals[index].1
            }
            saveError = error.localizedDescription
        }
    }

    /// 이슈 #66: quarter-workout-controller의 4번째 엔드포인트(workout-submissions)만
    /// 연동한다. 실제 서버 매치/쿼터가 아직 없어서(WorkoutRecord.matchId 주석 참고)
    /// iOS가 만든 matchId/quarterId를 그대로 보낸다 — 지금은 API가 호출되고 응답이
    /// 오는지 확인하는 디버깅 용도라, 결과는 콘솔 로그로만 남기고 분석 플로우 진행을
    /// 막지 않는다(화면은 호출부가 바로 다음으로 넘어간다).
    private func submitWorkouts() async {
        guard let matchId = entry.records.first?.matchId else { return }
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
        let ifMatch: String?
        do {
            let detail = try await NetworkService.provider.request(with: MatchEndpoints.detail(matchId: matchId))
            ifMatch = String(detail.data.version)
        } catch {
            ifMatch = nil
        }
        // 디버깅용 — 실제로 어떤 모양으로 요청했는지 전체 JSON과 요약을 콘솔에 남긴다.
        let requestBodyJSON = Self.prettyPrintedJSON(SubmissionBody(quarters: quarters))
        let requestSummary = Self.requestSummary(matchId: matchId, ifMatch: ifMatch, quarters: quarters)
        Self.logger.debug("workout-submissions 요청: \(requestSummary, privacy: .public)")
        Self.logger.debug("workout-submissions 요청 바디: \(requestBodyJSON, privacy: .public)")
        do {
            let result = try await NetworkService.provider.request(
                with: QuarterWorkoutEndpoints.submit(matchId: matchId, quarters: quarters, ifMatch: ifMatch)
            )
            Self.logger.debug("workout-submissions 성공: \(String(describing: result.data), privacy: .public)")
        } catch let NetworkError.invalidHttpStatusCode(statusCode, message) {
            Self.logger.debug("workout-submissions 실패: HTTP \(statusCode, privacy: .public) \(message ?? "", privacy: .public)")
        } catch {
            Self.logger.debug("workout-submissions 실패: \(String(describing: error), privacy: .public)")
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
