//
//  WorkoutSubmissionStore.swift
//  KIIKICK
//
//  이슈 #66에서 ReadyForDetailView 안에 인라인으로 있던 workout-submissions 제출
//  경로를 이슈 #96에서 분리했다.
//
//  재전송은 지원하지 않는다 — 서버가 구현하지 않았다(2026-11-15 확인). 제출은 경기당
//  한 번이고, 이미 제출된 경기의 운동장 변경은 FieldServerSync가 PATCH /matches로
//  처리한다.
//

import Foundation
import OSLog
import SwiftData

@MainActor
enum WorkoutSubmissionStore {
    private static let logger = Logger(subsystem: "KIIKICK", category: "WorkoutSubmission")

    /// 완료 경기와 쿼터를 원자적으로 제출한다.
    static func submit(
        records: [WorkoutRecord],
        positions: [String],
        context: ModelContext,
        provider: (any Provider)? = nil
    ) async throws {
        guard let firstRecord = records.first else { throw NetworkError.emptyData }
        let provider = provider ?? NetworkService.provider
        let matchId = firstRecord.matchId
        let repairedCount = try repairDuplicateQuarterIDs(in: records, context: context)
        if repairedCount > 0 {
            logger.debug("workout-submissions: 중복 quarterId \(repairedCount, privacy: .public)개를 새 UUID로 복구했습니다.")
        }
        try await ensureFieldsAreUploaded(for: records, context: context, provider: provider)

        let quarters = zip(records, positions).map { record, position in
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
                    field: workoutFieldPayload(for: record.field)
                )
            )
        }
        // If-Match: 제출 직전에 최신 경기 version을 조회해서 그대로 넘긴다. 조회가
        // 실패하면(서버에 아직 등록 안 된 경기) 버전을 모른다는 뜻이라 헤더 자체를
        // 생략한다(submit의 ifMatch: nil).
        // 재시도(네트워크 실패 등)에도 같은 키를 써서 서버가 같은 제출로 인식하게 한다.
        if firstRecord.submissionIdempotencyKey == nil {
            firstRecord.submissionIfMatch = try await latestVersion(matchId: matchId, provider: provider)
            firstRecord.submissionIdempotencyKey = UUID()
            try context.save()
        }
        let ifMatch = firstRecord.submissionIfMatch
        let requestSummary = Self.requestSummary(matchId: matchId, ifMatch: ifMatch, quarters: quarters)
        logger.debug("workout-submissions 요청: \(requestSummary, privacy: .public)")
        let result: MatchResultEnvelope<SubmissionReceipt> = try await provider.request(
            with: QuarterWorkoutEndpoints.submit(matchId: matchId, quarters: quarters,
                ifMatch: ifMatch, idempotencyKey: firstRecord.submissionIdempotencyKey)
        )
        logger.debug("workout-submissions 성공: \(String(describing: result.data), privacy: .public)")
    }

    /// 서버에 아직 등록되지 않은 경기(404)는 버전을 모르니 nil(= If-Match 헤더 생략)을 쓴다.
    private static func latestVersion(matchId: UUID, provider: any Provider) async throws -> String? {
        do {
            let detail = try await provider.request(with: MatchEndpoints.detail(matchId: matchId))
            return ifMatchValue(detail.data.version)
        } catch NetworkError.invalidHttpStatusCode(404, _) {
            // 서버 매치 생성 플로우가 로컬 녹화와 연결돼 있지 않아서(WorkoutRecord.matchId
            // 주석) 로컬에서 만든 matchId는 서버에 없을 수 있다. 그 경기는 재전송 자체가
            // 불가능하므로 팝업에서 바로 드러나게 적는다.
            logger.debug("GET /matches/\(matchId.uuidString.lowercased(), privacy: .public) 404 — 서버에 없는 경기라 If-Match를 생략합니다.")
            return nil
        }
    }

    /// If-Match는 HTTP entity-tag라 따옴표가 필수다(RFC 9110). 숫자만 보내면 서버가
    /// 같은 버전인데도 412 VERSION_CONFLICT(details.currentVersion이 보낸 값과 동일)로
    /// 거절한다 — 실기기에서 확인했다(이슈 #96). 이미 동작하는 QuarterFriendEndpoints도
    /// 같은 형식을 쓴다.
    static func ifMatchValue(_ version: Int) -> String { "\"\(version)\"" }

    /// 과거 앱 버전에서 같은 UUID로 저장된 여러 쿼터는 서버가 하나의 제출로 처리할 수
    /// 없다. 아직 서버에 저장되지 않은 로컬 기록이므로 두 번째 항목부터 새 ID로 바꿔
    /// 이후 재시도에도 같은 ID를 사용한다.
    private static func repairDuplicateQuarterIDs(in records: [WorkoutRecord], context: ModelContext) throws -> Int {
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
            try context.save()
        }
        return repairedCount
    }

    /// 새 UI가 생기기 전에 로컬에만 저장된 운동장도 분석 제출 전에 venues API에
    /// 등록한다. 새 경기장 생성은 FieldNamingView에서 즉시 등록하지만, 이 보정 경로는
    /// 기존 목록에서 선택한 운동장까지 보장한다.
    static func ensureFieldsAreUploaded(
        for records: [WorkoutRecord],
        context: ModelContext,
        provider: (any Provider)? = nil
    ) async throws {
        var uploaded: [Field] = []
        for field in records.compactMap(\.field) {
            guard !uploaded.contains(where: { $0 === field }) else { continue }
            try await VenueStore.ensureUploaded(field, context: context, provider: provider)
            uploaded.append(field)
        }
    }

    /// 팝업에 전체 JSON(특히 points/heartRateSamples)을 그대로 넣으면 너무 길어서, 핵심
    /// 필드만 뽑은 요약이다.
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

    /// 이슈 #66: WorkoutFieldRequest(cornerA-D 필수, name 필수)를 채운다 — 운동장이
    /// 미지정이면(record.field == nil) nil을 그대로 둔다. 서버가 그 경우까지 받아줄지는
    /// 확인 안 됐다.
    static func workoutFieldPayload(for field: Field?) -> WorkoutFieldPayload? {
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
}
