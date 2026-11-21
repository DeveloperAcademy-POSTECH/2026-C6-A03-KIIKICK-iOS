import Foundation
import SwiftData

/// 로컬 쿼터를 분석 목록과 홈에서 같은 경기 기준으로 묶는다.
enum WorkoutMatchGrouping {
    private static let maximumQuarterGap: TimeInterval = 10 * 60

    static func groups(from records: [WorkoutRecord]) -> [[WorkoutRecord]] {
        // 목업 경기와 이후 서버 제출 경로는 한 경기의 모든 쿼터에 같은
        // matchId를 부여한다. 먼저 이 명시적인 경기 경계를 보존해야 같은
        // 운동장("풋살장")을 재사용해도 다음 경기에 쿼터가 누적되지 않는다.
        let byMatchID = Dictionary(grouping: records, by: \.matchId)
        let explicitGroups = byMatchID.values
            .filter { $0.count > 1 }
            .map { $0.sorted { $0.date < $1.date } }

        // 과거 워치 레코드는 쿼터마다 matchId가 달라서 시간/운동장 기준을
        // fallback으로 사용한다. 역순/겹치는 레코드를 같은 경기로 묶지 않도록
        // gap의 하한도 확인한다.
        let legacyRecords = byMatchID.values
            .filter { $0.count == 1 }
            .flatMap { $0 }
        let sorted = legacyRecords.sorted { $0.date < $1.date }
        var groups: [[WorkoutRecord]] = []
        for record in sorted {
            if let last = groups.last?.last,
               last.field?.persistentModelID == record.field?.persistentModelID,
               record.date.timeIntervalSince(last.date.addingTimeInterval(last.duration)) >= 0,
               record.date.timeIntervalSince(last.date.addingTimeInterval(last.duration)) <= maximumQuarterGap {
                groups[groups.count - 1].append(record)
            } else {
                groups.append([record])
            }
        }

        return (explicitGroups + groups).sorted { lhs, rhs in
            (lhs.first?.date ?? .distantPast) < (rhs.first?.date ?? .distantPast)
        }
    }
}
