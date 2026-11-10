//
//  QuarterFriendEndpoints.swift
//  KIIKICK
//

import Foundation

enum QuarterFriendEndpoints {
    static func list(matchID: UUID, quarterID: UUID) -> Endpoint<VersionedEnvelope<[QuarterFriendResponse]>> {
        Endpoint(
            path: collectionPath(matchID: matchID, quarterID: quarterID),
            method: .get,
            headers: bearerHeaders()
        )
    }

    static func add(
        matchID: UUID,
        quarterID: UUID,
        friendUserID: UUID,
        matchVersion: Int,
        idempotencyKey: UUID
    ) -> Endpoint<Void> {
        mutation(
            method: .put,
            matchID: matchID,
            quarterID: quarterID,
            friendUserID: friendUserID,
            matchVersion: matchVersion,
            idempotencyKey: idempotencyKey
        )
    }

    static func remove(
        matchID: UUID,
        quarterID: UUID,
        friendUserID: UUID,
        matchVersion: Int,
        idempotencyKey: UUID
    ) -> Endpoint<Void> {
        mutation(
            method: .delete,
            matchID: matchID,
            quarterID: quarterID,
            friendUserID: friendUserID,
            matchVersion: matchVersion,
            idempotencyKey: idempotencyKey
        )
    }

    private static func mutation(
        method: HTTPMethod,
        matchID: UUID,
        quarterID: UUID,
        friendUserID: UUID,
        matchVersion: Int,
        idempotencyKey: UUID
    ) -> Endpoint<Void> {
        Endpoint(
            path: "\(collectionPath(matchID: matchID, quarterID: quarterID))/\(friendUserID.uuidString.lowercased())",
            method: method,
            headers: [
                "Idempotency-Key": idempotencyKey.uuidString,
                "If-Match": "\"\(matchVersion)\"",
            ].merging(bearerHeaders()) { _, bearer in bearer }
        )
    }

    private static func collectionPath(matchID: UUID, quarterID: UUID) -> String {
        "/api/v1/matches/\(matchID.uuidString.lowercased())/quarters/\(quarterID.uuidString.lowercased())/friends"
    }
}
