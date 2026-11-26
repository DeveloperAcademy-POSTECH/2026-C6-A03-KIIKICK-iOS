import CoreGraphics
import Foundation

struct MockHeatmapPoint: Codable, Hashable, Identifiable {
    let id: String
    let timestamp: Date
    let xMeters: Double
    let yMeters: Double
    let normalizedX: Double
    let normalizedY: Double
    let speedMps: Double
    let heartRateBpm: Double

    var normalizedPoint: CGPoint {
        CGPoint(x: normalizedX, y: normalizedY)
    }
}
