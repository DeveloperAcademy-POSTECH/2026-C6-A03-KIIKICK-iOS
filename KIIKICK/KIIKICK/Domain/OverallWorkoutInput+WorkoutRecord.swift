import Foundation

extension OverallWorkoutInput {
    init(record: WorkoutRecord) {
        self.init(
            date: record.date, durationSeconds: record.duration,
            distanceMeters: record.totalDistance, calories: record.totalCalories,
            samples: record.points.map {
                OverallSpeedSample(date: $0.timestamp, metersPerSecond: $0.speed)
            }
        )
    }
}
