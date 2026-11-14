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

import SwiftUI
import SwiftData

struct ReadyForDetailView: View {
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
    @State private var assignment: FieldAssignment
    /// 적용 범위를 물어보는 동안 들고 있는 선택된 운동장.
    @State private var pendingField: Field?
    @State private var fieldPickerScope: FieldAssignmentScope = .allQuarters
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
        _assignment = State(initialValue: FieldAssignment(
            quarters: entry.detail.quarters.map {
                FieldAssignment.QuarterInput(id: $0.id, record: $0.sourceRecord, field: $0.field)
            }
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.dateAndQuarter)
                    .font(.head2SB)
                    .foregroundStyle(.colorTextPrimary)

                directionGuide

                FieldChangeRow(field: assignment.commonField) {
                    fieldPickerScope = .allQuarters
                    isPresentingFieldPicker = true
                }
                .padding(16)
                .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))

                if hasMissingFields {
                    fieldAssignmentNotice
                }

                ForEach(Array(quarters.enumerated()), id: \.element.id) { index, quarter in
                    CardQuarterView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        field: field(for: quarter),
                        onChangeField: quarters.count > 1 ? {
                            fieldPickerScope = .quarter(quarter.id)
                            isPresentingFieldPicker = true
                        } : nil,
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
            FieldListView(onFieldSelected: handlePickedField)
        }
        .confirmationDialog("이 운동장을 어디에 적용할까요?", isPresented: Binding(
            get: { pendingField != nil }, set: { if !$0 { pendingField = nil } }
        ), titleVisibility: .visible) {
            Button("모든 쿼터에 적용") {
                if let pendingField { applyField(pendingField, to: .allQuarters) }
                pendingField = nil
            }
            Button("취소", role: .cancel) { pendingField = nil }
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
                    position: positions[index], field: field(for: quarter), points: quarter.points, events: quarter.events,
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
                    try await WorkoutSubmissionStore.submit(
                        records: entry.records,
                        positions: positions,
                        context: modelContext
                    )
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

    private var hasMissingFields: Bool { assignment.hasMissingFields }

    private func field(for quarter: AnalysisQuarter) -> Field? { assignment.field(for: quarter.id) }

    private var fieldAssignmentNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("운동장이 지정되지 않은 쿼터가 있어요")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text("운동장을 지정하면 히트맵과 분석 결과를 정확히 볼 수 있어요.")
                .font(.body4R)
                .foregroundStyle(.colorTextSecondary)
            CtaView(text: "운동장 지정하기", type: .secondary, size: .small) {
                fieldPickerScope = .allQuarters
                isPresentingFieldPicker = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
    }

    /// 경기 단위로 들어왔고 이미 모든 쿼터에 운동장이 있을 때만 적용 범위를 묻는다 —
    /// 최초 지정(미지정 쿼터가 있는 상태)과 쿼터가 하나뿐인 경기는 바로 적용한다.
    private func handlePickedField(_ field: Field) {
        if case .allQuarters = fieldPickerScope, quarters.count > 1, !assignment.hasMissingFields {
            pendingField = field
            return
        }
        applyField(field, to: fieldPickerScope)
    }

    private func applyField(_ field: Field, to scope: FieldAssignmentScope) {
        do {
            try assignment.apply(field, to: scope, save: { try modelContext.save() })
        } catch {
            saveError = error.localizedDescription
        }
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
