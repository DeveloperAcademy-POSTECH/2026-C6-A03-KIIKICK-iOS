import Foundation
import SwiftData

/// 매치 식별자가 없는 로컬 쿼터를 분석 목록과 홈에서 같은 기준으로 묶는다.
enum WorkoutMatchGrouping {
    private static let maximumQuarterGap: TimeInterval = 10 * 60

    static func groups(from records: [WorkoutRecord]) -> [[WorkoutRecord]] {
        let sorted = records.sorted { $0.date < $1.date }
        var groups: [[WorkoutRecord]] = []
        for record in sorted {
            if let last = groups.last?.last,
               last.field?.persistentModelID == record.field?.persistentModelID,
               record.date.timeIntervalSince(last.date.addingTimeInterval(last.duration)) <= maximumQuarterGap {
                groups[groups.count - 1].append(record)
            } else {
                groups.append([record])
            }
        }
        return groups
    }
}
