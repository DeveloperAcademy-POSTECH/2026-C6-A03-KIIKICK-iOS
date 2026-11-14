//
//  FieldServerSync.swift
//  KIIKICK
//
//  이슈 #96: 이미 제출된 경기의 운동장이 바뀌었을 때 서버 값을 맞춘다.
//
//  쿼터 리소스에는 venue 필드가 없고, 운동장은 workout.field(WorkoutPayload)에만
//  붙는다. 한때 workout-submissions 재전송으로 쿼터별 field까지 갱신하려 했지만
//  서버가 재전송을 구현하지 않아 그 경로는 뺐다(2026-11-15 확인). 지금 쓸 수 있는 건
//  경기 단위 venue를 바꾸는 SET-09 PATCH /matches 하나뿐이라, 쿼터의 workout.field는
//  옛 값으로 남는다 — 서버가 재전송이나 운동장 변경 전용 엔드포인트를 열어주면 그때
//  쿼터 단위까지 맞출 수 있다.
//
//  실패해도 로컬 수정은 그대로 두고 호출부가 "서버 반영 실패"를 안내한다 — 히트맵은
//  로컬 값으로 그리므로 화면은 이미 맞다.
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

        guard let venueID = field.serverID else { throw NetworkError.emptyData }
        let _: Envelope<MatchResponse> = try await provider.request(with: MatchEndpoints.update(
            matchId: matchId,
            venueId: venueID,
            venueSnapshot: VenueSnapshot(name: field.name, address: field.address),
            ifMatch: WorkoutSubmissionStore.ifMatchValue(version)
        ))
        logger.debug("PATCH /matches 운동장 반영 완료: \(field.name, privacy: .public)")
        return .matchPatched
    }
}
