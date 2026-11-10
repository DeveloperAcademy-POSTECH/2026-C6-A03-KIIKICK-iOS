//
//  VenueEndpoints.swift
//  KIIKICK
//

import Foundation

enum VenueEndpoints {
    private struct ListQuery: Encodable {
        let q: String?
        let cursor: String?
        let limit: Int?
    }

    static func list(q: String? = nil, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<VenueResponse>> {
        Endpoint(
            path: "/api/v1/venues",
            method: .get,
            queryParameters: ListQuery(q: q, cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }

    static func detail(venueID: UUID) -> Endpoint<Envelope<VenueResponse>> {
        Endpoint(
            path: "/api/v1/venues/\(venueID.uuidString.lowercased())",
            method: .get,
            headers: bearerHeaders()
        )
    }

    static func create(request: VenueCreateRequest, idempotencyKey: UUID) -> Endpoint<Envelope<VenueResponse>> {
        Endpoint(
            path: "/api/v1/venues",
            method: .post,
            bodyParameters: request,
            headers: mutationHeaders(idempotencyKey: idempotencyKey)
        )
    }

    static func update(
        venueID: UUID,
        request: VenueCreateRequest,
        idempotencyKey: UUID
    ) -> Endpoint<Envelope<VenueResponse>> {
        Endpoint(
            path: "/api/v1/venues/\(venueID.uuidString.lowercased())",
            method: .patch,
            bodyParameters: request,
            headers: mutationHeaders(idempotencyKey: idempotencyKey)
        )
    }

    static func delete(venueID: UUID, idempotencyKey: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/venues/\(venueID.uuidString.lowercased())",
            method: .delete,
            headers: mutationHeaders(idempotencyKey: idempotencyKey)
        )
    }

    private static func mutationHeaders(idempotencyKey: UUID) -> [String: String] {
        ["Idempotency-Key": idempotencyKey.uuidString]
            .merging(bearerHeaders()) { _, bearer in bearer }
    }
}
