import Foundation
import SwiftData

@main
struct TrackingSettingsChecks {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[2])
        let configuration = ModelConfiguration(url: url)
        let container = try ModelContainer(for: WorkoutRecord.self, Field.self, configurations: configuration)
        let context = container.mainContext
        if CommandLine.arguments[1] == "write" {
            let point = TrackPoint(latitude: 37, longitude: 127, altitude: 10, horizontalAccuracy: 3,
                speed: 7, course: 0, timestamp: Date(timeIntervalSince1970: 1))
            let record = WorkoutRecord(payload: WorkoutPayload(startDate: point.timestamp,
                endDate: point.timestamp.addingTimeInterval(10), points: [point], heartRateSamples: [],
                totalCalories: 5, totalDistance: 20, events: []))
            precondition(record.position == nil && !record.isAttackDirectionReversed)
            record.position = "CM"
            record.isAttackDirectionReversed = true
            context.insert(record)
            try context.save()
        } else {
            let records = try context.fetch(FetchDescriptor<WorkoutRecord>())
            precondition(records.count == 1)
            let record = records[0]
            precondition(record.position == "CM" && record.isAttackDirectionReversed)
            precondition(record.points.count == 1 && record.points[0].latitude == 37 && record.points[0].longitude == 127,
                "방향 설정을 저장해도 원본 GPS를 유지해야 한다")
            print("Tracking settings checks passed: settings survive process restart and GPS remains unchanged.")
        }
    }
}
