//
//  FieldServerSync.swift
//  KIIKICK
//
//  이슈 #96: 이미 제출된 경기의 운동장이 바뀌었을 때 서버 값을 맞춘다.
//
//  쿼터 리소스에는 venue 필드가 없고, 운동장은 workout.field(WorkoutPayload)에만
//  붙는다. 이미 제출된 쿼터의 field만 바꾸는 전용 엔드포인트가 없어서 두 단계로 간다.
//    B) workout-submissions 재전송 — 쿼터별 field까지 맞지만, 서버가 중복 제출을
//       막거나 쿼터를 또 만들 수 있어 실제 동작 확인이 필요하다(이슈 #96).
//    A) PATCH /matches venueId — 공식 API(SET-09). 경기 대표 운동장만 맞고 쿼터
//       workout.field는 옛 값으로 남는다.
//  B가 어떤 이유로든 실패하면 A로 떨어진다. 둘 다 실패해도 로컬 수정은 그대로 두고
//  호출부가 "서버 반영 실패"를 안내한다 — 히트맵은 로컬 값으로 그리므로 화면은 맞다.
//

import Foundation
import OSLog
import SwiftData

@MainActor
enum FieldServerSync {
    private static let logger = Logger(subsystem: "KIIKICK", category: "FieldServerSync")

    enum Outcome: Equatable {
        /// 아직 제출된 적 없는 경기 — 바뀐 운동장은 첫 제출에 실려 간다.
        case skippedNotSubmitted
        /// 서버에 등록되지 않은 경기(detail 404) — 로컬 수정만 남긴다.
        case skippedMatchMissing
        case resubmitted
        case matchPatched
    }

    static func sync(
        records: [WorkoutRecord],
        positions: [String],
        field: Field,
        context: ModelContext,
        provider: (any Provider)? = nil
    ) async throws -> Outcome {
        guard let firstRecord = records.first else { throw NetworkError.emptyData }
        guard firstRecord.submissionIdempotencyKey != nil else { return .skippedNotSubmitted }
        let provider = provider ?? NetworkService.provider
        let matchId = firstRecord.matchId

        try await VenueStore.ensureUploaded(field, context: context, provider: provider)

        let version: Int
        do {
            let detail = try await provider.request(with: MatchEndpoints.detail(matchId: matchId))
            version = detail.data.version
        } catch NetworkError.invalidHttpStatusCode(404, _) {
            return .skippedMatchMissing
        }

        let previousKey = firstRecord.submissionIdempotencyKey
        let previousIfMatch = firstRecord.submissionIfMatch
        do {
            try await WorkoutSubmissionStore.submit(
                records: records, positions: positions,
                mode: .resubmission, context: context, provider: provider
            )
            return .resubmitted
        } catch {
            logger.debug("운동장 재전송 실패, PATCH /matches로 폴백: \(error.localizedDescription, privacy: .public)")
            // 재전송이 실패했으면 원래 제출 상태를 깨지 않도록 식별자를 되돌린다.
            firstRecord.submissionIdempotencyKey = previousKey
            firstRecord.submissionIfMatch = previousIfMatch
            try context.save()
        }

        guard let venueID = field.serverID else { throw NetworkError.emptyData }
        let _: Envelope<MatchResponse> = try await provider.request(with: MatchEndpoints.update(
            matchId: matchId,
            venueId: venueID,
            venueSnapshot: VenueSnapshot(name: field.name, address: field.address),
            ifMatch: WorkoutSubmissionStore.ifMatchValue(version)
        ))
        return .matchPatched
    }
}
