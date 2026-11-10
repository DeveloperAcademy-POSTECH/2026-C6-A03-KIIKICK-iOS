//
//  FriendHeatmapDTO.swift
//  KIIKICK
//

import Foundation

struct FriendHeatmapEnvelope: Decodable {
    let data: FriendHeatmapResponse
    let meta: MatchResultMeta
}

struct FriendHeatmapResponse: Decodable {
    let quarterId: UUID
    let status: Status
    let cellSizeDegrees: Double
    let sampleCount: Int
    let cells: [FriendHeatmapCell]

    enum Status: String, Decodable {
        case ready = "READY"
        case noValidPoints = "NO_VALID_POINTS"
        case missingWorkout = "MISSING_WORKOUT"
    }
}

struct FriendHeatmapCell: Decodable {
    let latitude: Double
    let longitude: Double
    let sampleCount: Int
}
