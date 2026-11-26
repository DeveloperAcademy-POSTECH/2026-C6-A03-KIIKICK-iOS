import Foundation

struct MockHeatmapPlayer: Codable, Hashable, Identifiable {
    let id: String
    let displayName: String
    let role: String
    let quarters: [MockHeatmapQuarter]

    var allPoints: [MockHeatmapPoint] {
        quarters.flatMap(\.points)
    }

    var averageSpeedKmh: Double {
        guard !allPoints.isEmpty else { return 0 }
        return allPoints.map(\.speedMps).reduce(0, +) / Double(allPoints.count) * 3.6
    }

    var maxSpeedKmh: Double {
        (allPoints.map(\.speedMps).max() ?? 0) * 3.6
    }

    var averageHeartRate: Double {
        guard !allPoints.isEmpty else { return 0 }
        return allPoints.map(\.heartRateBpm).reduce(0, +) / Double(allPoints.count)
    }
}
