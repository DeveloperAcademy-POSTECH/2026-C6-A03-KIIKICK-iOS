import Foundation

struct MockHeatmapEvent: Codable, Hashable, Identifiable {
    let id: String
    let type: MockHeatmapEventType
    let pointIndex: Int
    let timestamp: Date
}
