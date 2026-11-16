import Foundation

struct MockHeatmapMatch: Codable, Hashable, Identifiable {
    let id: String
    let seed: Int
    let startedAt: Date
    let quarterDuration: TimeInterval
    let secondsPerPoint: TimeInterval
    let players: [MockHeatmapPlayer]
}
