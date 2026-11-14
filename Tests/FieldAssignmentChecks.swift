import Foundation
import SwiftData

@main
struct FieldAssignmentChecks {
    @MainActor
    static func main() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Field.self, WorkoutRecord.self, configurations: configuration)
        let context = container.mainContext

        let fieldA = makeField(name: "A구장")
        let fieldB = makeField(name: "B구장")
        context.insert(fieldA)
        context.insert(fieldB)
        let first = makeRecord()
        let second = makeRecord()
        first.field = fieldA
        second.field = fieldA
        context.insert(first)
        context.insert(second)
        try context.save()

        let firstID = UUID()
        let secondID = UUID()
        let inputs = [
            FieldAssignment.QuarterInput(id: firstID, record: first, field: nil),
            FieldAssignment.QuarterInput(id: secondID, record: second, field: nil),
        ]

        // 초기 상태: record.field가 오버레이로 올라오고 공통 운동장이 잡힌다.
        var assignment = FieldAssignment(quarters: inputs)
        precondition(assignment.field(for: firstID) === fieldA)
        precondition(assignment.commonField === fieldA)
        precondition(!assignment.hasMissingFields)
        precondition(assignment.isEditable)

        // 일괄 적용
        try assignment.apply(fieldB, to: .allQuarters, save: { try context.save() })
        precondition(assignment.field(for: firstID) === fieldB)
        precondition(assignment.field(for: secondID) === fieldB)
        precondition(first.field === fieldB && second.field === fieldB)

        // 쿼터 단위 적용 — 다른 쿼터는 그대로
        try assignment.apply(fieldA, to: .quarter(secondID), save: { try context.save() })
        precondition(assignment.field(for: firstID) === fieldB)
        precondition(assignment.field(for: secondID) === fieldA)
        precondition(assignment.commonField == nil)

        // 저장 실패 시 오버레이와 record.field가 모두 되돌아온다.
        struct SaveFailure: Error {}
        do {
            try assignment.apply(fieldB, to: .allQuarters, save: { throw SaveFailure() })
            preconditionFailure("저장 실패가 전달되지 않았습니다")
        } catch is SaveFailure {
            precondition(assignment.field(for: firstID) === fieldB)
            precondition(assignment.field(for: secondID) === fieldA)
            precondition(first.field === fieldB && second.field === fieldA)
        }

        // 운동장 미지정 쿼터는 missingQuarterIDs로 드러난다.
        let third = makeRecord()
        context.insert(third)
        try context.save()
        let thirdID = UUID()
        let withMissing = FieldAssignment(quarters: inputs + [
            FieldAssignment.QuarterInput(id: thirdID, record: third, field: nil),
        ])
        precondition(withMissing.missingQuarterIDs == [thirdID])
        precondition(withMissing.hasMissingFields)
        precondition(withMissing.targetQuarterIDs(for: .allQuarters) == [firstID, secondID, thirdID])
        precondition(withMissing.targetQuarterIDs(for: .quarter(thirdID)) == [thirdID])

        // 로컬 기록이 없는(서버 복원) 엔트리는 편집 대상이 아니다.
        let restored = FieldAssignment(quarters: [
            FieldAssignment.QuarterInput(id: firstID, record: nil, field: fieldA),
        ])
        precondition(!restored.isEditable)
        precondition(restored.field(for: firstID) === fieldA)

        print("FieldAssignmentChecks 통과")
    }

    private static func makeField(name: String) -> Field {
        let corners = (0..<4).map { index in
            FieldCorner(latitude: 37.0 + Double(index) * 0.001, longitude: 127.0 + Double(index) * 0.001)
        }
        return Field(
            name: name,
            cornerA: corners[0], cornerB: corners[1], cornerC: corners[2], cornerD: corners[3]
        )
    }

    private static func makeRecord() -> WorkoutRecord {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let points = (0..<3).map { index in
            TrackPoint(
                latitude: 37.0 + Double(index) * 0.0001, longitude: 127.0 + Double(index) * 0.0001,
                altitude: 20, horizontalAccuracy: 5, speed: 2, course: 90,
                timestamp: start.addingTimeInterval(Double(index) * 5)
            )
        }
        return WorkoutRecord(payload: WorkoutPayload(
            startDate: start,
            endDate: start.addingTimeInterval(600),
            points: points,
            heartRateSamples: [HeartRateSample(timestamp: start, bpm: 120)],
            totalCalories: 100,
            totalDistance: 1000,
            events: [],
            field: nil,
            position: .cm
        ))
    }
}
