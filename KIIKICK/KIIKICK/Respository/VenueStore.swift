//
//  VenueStore.swift
//  KIIKICK
//

import Foundation
import SwiftData

@MainActor
enum VenueStore {
    static func create(
        name: String,
        correctedCorners: [FieldCorner],
        rawCorners: [FieldCorner],
        idempotencyKey: UUID,
        context: ModelContext,
        provider: Provider? = nil
    ) async throws -> Field {
        guard correctedCorners.count == 4, rawCorners.count == 4 else {
            throw NetworkError.components
        }
        let provider = provider ?? NetworkService.provider
        let request = VenueCreateRequest(name: name, corrected: correctedCorners, raw: rawCorners)
        let response: Envelope<VenueResponse> = try await provider.request(
            with: VenueEndpoints.create(request: request, idempotencyKey: idempotencyKey)
        )
        let field = try makeField(from: response.data)
        context.insert(field)
        do {
            try context.save()
            return field
        } catch {
            context.delete(field)
            throw error
        }
    }

    static func update(
        _ field: Field,
        name: String,
        correctedCorners: [FieldCorner],
        rawCorners: [FieldCorner],
        idempotencyKey: UUID,
        context: ModelContext,
        provider: Provider? = nil
    ) async throws {
        guard correctedCorners.count == 4, rawCorners.count == 4 else {
            throw NetworkError.components
        }
        let provider = provider ?? NetworkService.provider
        let request = VenueCreateRequest(name: name, corrected: correctedCorners, raw: rawCorners)
        let response: Envelope<VenueResponse>
        if let serverID = field.serverID {
            response = try await provider.request(
                with: VenueEndpoints.update(
                    venueID: serverID,
                    request: request,
                    idempotencyKey: idempotencyKey
                )
            )
        } else {
            response = try await provider.request(
                with: VenueEndpoints.create(
                    request: request,
                    idempotencyKey: idempotencyKey
                )
            )
        }
        try apply(response.data, to: field)
        try context.save()
    }

    static func archive(
        _ field: Field,
        idempotencyKey: UUID,
        context: ModelContext,
        provider: Provider? = nil
    ) async throws {
        let provider = provider ?? NetworkService.provider
        var serverID = field.serverID
        if serverID == nil, let createKey = field.createIdempotencyKey {
            let response: Envelope<VenueResponse> = try await provider.request(
                with: VenueEndpoints.create(request: VenueCreateRequest(field: field), idempotencyKey: createKey)
            )
            try apply(response.data, to: field)
            try context.save()
            serverID = response.data.id
        }
        if let serverID {
            do {
                try await provider.requestWithoutResponse(
                    with: VenueEndpoints.delete(venueID: serverID, idempotencyKey: idempotencyKey)
                )
            } catch NetworkError.invalidHttpStatusCode(404, _) {
                // 이미 다른 기기에서 삭제된 경우도 원하는 최종 상태와 같다.
            }
        }
        field.isArchived = true
        try context.save()
    }

    /// API 연동 전부터 기기에 있던 운동장을 제출 경로에서도 서버에 먼저 저장한다.
    /// 멱등 키를 로컬에 보관해 앱이 중단된 뒤 재시도해도 중복 경기장이 생기지 않는다.
    static func ensureUploaded(
        _ field: Field,
        context: ModelContext,
        provider: Provider? = nil
    ) async throws {
        guard field.serverID == nil else { return }

        let provider = provider ?? NetworkService.provider
        if field.createIdempotencyKey == nil {
            field.createIdempotencyKey = UUID()
            try context.save()
        }
        guard let idempotencyKey = field.createIdempotencyKey else {
            throw NetworkError.components
        }

        let response: Envelope<VenueResponse> = try await provider.request(
            with: VenueEndpoints.create(
                request: VenueCreateRequest(field: field),
                idempotencyKey: idempotencyKey
            )
        )
        try apply(response.data, to: field)
        field.createIdempotencyKey = nil
        try context.save()
    }

    /// 서버 목록을 내려받고, API 도입 전에 저장된 로컬 경기장은 한 번만 서버로 이전한다.
    static func synchronize(
        context: ModelContext,
        provider: Provider? = nil
    ) async throws {
        let provider = provider ?? NetworkService.provider
        var remoteVenues: [VenueResponse] = []
        var cursor: String?
        var seenCursors = Set<String>()

        repeat {
            try Task.checkCancellation()
            let page: PageEnvelope<VenueResponse> = try await provider.request(
                with: VenueEndpoints.list(cursor: cursor, limit: 100)
            )
            remoteVenues.append(contentsOf: page.data)
            guard page.meta.pagination.hasNext else { break }
            guard let nextCursor = page.meta.pagination.nextCursor,
                  seenCursors.insert(nextCursor).inserted else {
                throw NetworkError.components
            }
            cursor = nextCursor
        } while true

        let localFields = try context.fetch(FetchDescriptor<Field>())
        var localByServerID: [UUID: Field] = [:]
        for field in localFields {
            if let serverID = field.serverID, localByServerID[serverID] == nil {
                localByServerID[serverID] = field
            }
        }
        let remoteIDs = Set(remoteVenues.map(\.id))

        for venue in remoteVenues {
            guard venue.correctedCorners != nil else { continue }
            if let field = localByServerID[venue.id] {
                try apply(venue, to: field)
                field.isArchived = false
            } else {
                let field = try makeField(from: venue)
                context.insert(field)
                localByServerID[venue.id] = field
            }
        }

        for field in localFields {
            if let serverID = field.serverID, !remoteIDs.contains(serverID) {
                field.isArchived = true
            }
        }
        try context.save()

        for field in localFields where field.serverID == nil && !field.isArchived {
            try Task.checkCancellation()
            try await ensureUploaded(field, context: context, provider: provider)
        }
    }

    private static func makeField(from venue: VenueResponse) throws -> Field {
        guard let corners = venue.correctedCorners else { throw NetworkError.decodeError }
        return Field(
            name: venue.name,
            cornerA: corners[0], cornerB: corners[1], cornerC: corners[2], cornerD: corners[3],
            rawCornerA: venue.rawCornerA, rawCornerB: venue.rawCornerB,
            rawCornerC: venue.rawCornerC, rawCornerD: venue.rawCornerD,
            serverID: venue.id, address: venue.address, serverUpdatedAt: venue.updatedAt
        )
    }

    private static func apply(_ venue: VenueResponse, to field: Field) throws {
        guard let corners = venue.correctedCorners else { throw NetworkError.decodeError }
        field.name = venue.name
        field.serverID = venue.id
        field.address = venue.address
        field.serverUpdatedAt = venue.updatedAt
        field.cornerA = corners[0]
        field.cornerB = corners[1]
        field.cornerC = corners[2]
        field.cornerD = corners[3]
        field.rawCornerA = venue.rawCornerA
        field.rawCornerB = venue.rawCornerB
        field.rawCornerC = venue.rawCornerC
        field.rawCornerD = venue.rawCornerD
        field.isArchived = false
        field.createIdempotencyKey = nil
    }
}
