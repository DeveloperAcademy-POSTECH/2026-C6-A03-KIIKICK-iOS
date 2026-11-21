import Foundation

extension OverallWorkoutInput {
    init?(quarter: AnalysisQuarter) {
        guard let date = quarter.startDate else { return nil }
        self.init(
            date: date, durationSeconds: quarter.duration,
            distanceMeters: quarter.totalDistanceKm * 1000, calories: quarter.totalCaloriesKcal,
            samples: quarter.points.map {
                OverallSpeedSample(date: $0.timestamp, metersPerSecond: $0.speed)
            }
        )
    }
}
