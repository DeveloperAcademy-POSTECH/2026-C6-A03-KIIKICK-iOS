import Foundation
import SwiftData

@main
struct OverallStoredRecordsChecks {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[2])
        let configuration = ModelConfiguration(url: url)
        let container = try ModelContainer(for: WorkoutRecord.self, Field.self, configurations: configuration)
        let context = container.mainContext
        if CommandLine.arguments[1] == "write" {
            let start = Date(timeIntervalSince1970: 1_793_491_200)
            let points = [0.0, 1, 2, 2, 1, 0].enumerated().map { index, speed in
                TrackPoint(latitude: 37, longitude: 127, altitude: 10, horizontalAccuracy: 3,
                           speed: speed, course: 0, timestamp: start.addingTimeInterval(Double(index)))
            }
            let recorded = WorkoutRecord(payload: WorkoutPayload(startDate: start,
                endDate: start.addingTimeInterval(60), points: points, heartRateSamples: [],
                totalCalories: 10, totalDistance: 100, events: []))
            let withoutSpeed = WorkoutRecord(payload: WorkoutPayload(startDate: start.addingTimeInterval(120),
                endDate: start.addingTimeInterval(180), points: [], heartRateSamples: [],
                totalCalories: 20, totalDistance: 200, events: []))
            context.insert(recorded)
            context.insert(withoutSpeed)
            try context.save()
        } else {
            var records = try context.fetch(FetchDescriptor<WorkoutRecord>(sortBy: [SortDescriptor(\.date)]))
            precondition(records.count == 2, "프로세스 재시작 후 저장된 기록을 읽는다")
            let inputs = records.map(OverallWorkoutInput.init(record:))
            let workouts = inputs.compactMap { $0.workout() }
            precondition(workouts.count == 1, "속도 누락 기록은 OVR에서만 제외한다")
            precondition(workouts[0].durationSeconds == 60 && workouts[0].distanceMeters == 100)
            precondition(abs(workouts[0].peakSpeedKmh - 7.2) < 0.000001)
            precondition(workouts[0].accelerationCount == 1 && workouts[0].decelerationCount == 1)
            let history = OverallCalculator.history(from: workouts)
            precondition(history.current?.score == 80 && history.delta == nil)
            precondition(records.reduce(0) { $0 + $1.totalDistance } == 300,
                         "홈 총 거리는 OVR 제외 기록도 포함한다")
            records[0].totalDistance = 200
            try context.save()
            let updated = records.map(OverallWorkoutInput.init(record:))
            precondition(inputs != updated, "저장 기록 변경이 홈 재계산 입력에 반영된다")
            precondition(OverallCalculator.history(from: updated.compactMap { $0.workout() }).current?.score == 106)
            context.delete(records[0])
            try context.save()
            records = try context.fetch(FetchDescriptor<WorkoutRecord>())
            precondition(OverallCalculator.history(from: records.compactMap { OverallWorkoutInput(record: $0).workout() }).current == nil,
                         "마지막 유효 기록을 삭제하면 OVR이 비어야 한다")
            print("PASS: 저장 기록 재조회·속도 단위 변환·OVR 제외·수정·삭제 반영")
        }
    }
}
