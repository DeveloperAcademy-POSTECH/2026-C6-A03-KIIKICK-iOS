import Foundation

struct MockHeatmapQuarter: Codable, Hashable, Identifiable {
    let number: Int
    let duration: TimeInterval
    let points: [MockHeatmapPoint]
    let events: [MockHeatmapEvent]

    var id: Int { number }

    var goalCount: Int {
        events.count(where: { $0.type == .goal })
    }

    var assistCount: Int {
        events.count(where: { $0.type == .assist })
    }
}
