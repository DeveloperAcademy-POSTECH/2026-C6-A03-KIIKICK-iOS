//
//  FieldAssignment.swift
//  KIIKICK
//
//  이슈 #96: 쿼터별 운동장을 바꾸는 공통 로직. AnalysisQuarter가 값 타입이라
//  record.field만 고쳐도 화면이 갱신되지 않으므로, 뷰가 @State로 들고 있는 이
//  오버레이를 히트맵(TrackingMapPager)에 넘긴다.
//
//  `save`를 주입받는 이유: 로컬 저장이 실패하면 메모리 상태와 record.field를 모두
//  원래대로 되돌려야 하고, 그 롤백을 ModelContext 없이 검증할 수 있어야 한다.
//

import Foundation
import SwiftData

enum FieldAssignmentScope: Equatable {
    /// 경기의 모든 쿼터에 같은 운동장을 적용한다(기본).
    case allQuarters
    case quarter(UUID)
}

struct FieldAssignment {
    struct QuarterInput {
        let id: UUID
        let record: WorkoutRecord?
        /// 서버에서 복원된 엔트리처럼 로컬 기록이 없을 때의 표시용 운동장.
        let field: Field?
    }

    private var fieldsByQuarterID: [UUID: Field]
    private let recordsByQuarterID: [UUID: WorkoutRecord]
    private let quarterIDs: [UUID]

    init(quarters: [QuarterInput]) {
        var fields: [UUID: Field] = [:]
        var records: [UUID: WorkoutRecord] = [:]
        for quarter in quarters {
            if let record = quarter.record {
                records[quarter.id] = record
            }
            if let field = quarter.record?.field ?? quarter.field {
                fields[quarter.id] = field
            }
        }
        quarterIDs = quarters.map(\.id)
        fieldsByQuarterID = fields
        recordsByQuarterID = records
    }

    func field(for quarterID: UUID) -> Field? { fieldsByQuarterID[quarterID] }

    var missingQuarterIDs: [UUID] { quarterIDs.filter { fieldsByQuarterID[$0] == nil } }

    var hasMissingFields: Bool { !missingQuarterIDs.isEmpty }

    /// 로컬 기록이 없으면 바꿀 대상이 없다(서버에서 복원한 엔트리).
    var isEditable: Bool { !recordsByQuarterID.isEmpty }

    /// 모든 쿼터가 같은 운동장일 때 그 운동장, 쿼터마다 다르거나 비어 있으면 nil.
    var commonField: Field? {
        guard let first = quarterIDs.first, let field = fieldsByQuarterID[first] else { return nil }
        for id in quarterIDs.dropFirst() where fieldsByQuarterID[id] !== field { return nil }
        return field
    }

    func targetQuarterIDs(for scope: FieldAssignmentScope) -> [UUID] {
        switch scope {
        case .allQuarters: quarterIDs
        case .quarter(let id): quarterIDs.contains(id) ? [id] : []
        }
    }

    /// 오버레이를 반영한 쿼터 목록. AnalysisQuarter.field가 `let`이라 record.field만
    /// 고치면 이 값 타입은 옛 운동장을 들고 있고, 그대로 하위 뷰(TimelineView 등)로
    /// 내려가 거기서는 바뀌지 않은 것처럼 보인다 — 내려보내기 전에 여기서 교정한다.
    func applying(to quarters: [AnalysisQuarter]) -> [AnalysisQuarter] {
        quarters.map { quarter in
            guard let field = fieldsByQuarterID[quarter.id], field !== quarter.field else { return quarter }
            var updated = AnalysisQuarter(
                id: quarter.id, quarterNumber: quarter.quarterNumber, durationText: quarter.durationText,
                startDate: quarter.startDate, duration: quarter.duration, position: quarter.position,
                field: field, points: quarter.points, events: quarter.events,
                totalDistanceKm: quarter.totalDistanceKm, totalCaloriesKcal: quarter.totalCaloriesKcal
            )
            updated.isAttackDirectionReversed = quarter.isAttackDirectionReversed
            updated.sourceRecord = quarter.sourceRecord
            updated.resultStats = quarter.resultStats
            updated.resultSections = quarter.resultSections
            updated.resultGoals = quarter.resultGoals
            updated.resultAssists = quarter.resultAssists
            return updated
        }
    }

    mutating func apply(
        _ field: Field,
        to scope: FieldAssignmentScope,
        save: () throws -> Void
    ) throws {
        let targets = targetQuarterIDs(for: scope)
        guard !targets.isEmpty else { return }
        let previousOverlay = fieldsByQuarterID
        var previousRecordFields: [UUID: Field?] = [:]
        for id in targets {
            previousRecordFields[id] = recordsByQuarterID[id]?.field
            recordsByQuarterID[id]?.field = field
            fieldsByQuarterID[id] = field
        }
        do {
            try save()
        } catch {
            for id in targets {
                recordsByQuarterID[id]?.field = previousRecordFields[id] ?? nil
            }
            fieldsByQuarterID = previousOverlay
            throw error
        }
    }
}
