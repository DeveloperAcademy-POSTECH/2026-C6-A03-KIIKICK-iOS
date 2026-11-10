import Foundation
import SwiftData
import SwiftUI

// 앱의 인증 저장소만 대체하고, 실제 라우터·경기 모델·분석 빌더를 사용한다.
enum UserSession { static let requiresOnboarding = false }

@main
struct NotificationRoutingChecks {
    @MainActor static func main() throws {
        let configuration = ModelConfiguration(url: URL(fileURLWithPath: CommandLine.arguments[2]))
        let container = try ModelContainer(for: WorkoutRecord.self, Field.self, configurations: configuration)
        let context = container.mainContext
        if CommandLine.arguments[1] == "write" {
            let start = Date(timeIntervalSince1970: 1_793_491_200)
            let offsets: [TimeInterval] = [0, 12 * 60, 3 * 60 * 60]
            for offset in offsets {
                var payload = WorkoutPayload(startDate: start.addingTimeInterval(offset),
                    endDate: start.addingTimeInterval(offset + 600), points: [], heartRateSamples: [],
                    totalCalories: 10, totalDistance: 100, events: [])
                payload.position = .cm
                context.insert(WorkoutRecord(payload: payload))
            }
            try context.save()
        } else if CommandLine.arguments[1] == "read" {
            let records = try context.fetch(FetchDescriptor<WorkoutRecord>(sortBy: [SortDescriptor(\.date)]))
            let entries = AnalysisEntry.grouped(from: records)
            precondition(entries.count == 2 && entries.last?.records.count == 2,
                         "알림과 목록은 같은 경기의 전체 쿼터를 사용해야 한다")
            let entry = entries.last!
            precondition(!entry.hasViewedAnalysis)
            let router = AppRouter()
            router.showNotifications(in: .home)
            precondition(router.paths[.home]?.count == 1)
            let firstRoute = router.showAnalysis(entry)
            precondition(router.paths[.home]?.count == 2 && router.paths[.analysis] == nil)
            guard case .ready = firstRoute else { fatalError("첫 진입은 분석 준비") }
            router.pushAnalysis(.analyzing(entry), in: .home)
            precondition(router.paths[.home]?.count == 3)
            let analyzingPathCount = router.paths[.home]!.count
            // 분석 중 다른 탭으로 전환해도 원래 탭의 스택만 갱신한다.
            router.selection = .friends
            router.finishAnalysis(entry, in: .home, expectedPathCount: analyzingPathCount)
            precondition(router.paths[.home]?.count == 2 && router.paths[.friends] == nil)
            router.selection = .home
            router.pop()
            precondition(router.paths[.home]?.count == 1, "뒤로 가면 알림 목록이 남아야 한다")
            for record in entry.records { record.hasViewedAnalysis = true }
            try context.save()
            let viewedRoute = router.showAnalysis(entry)
            guard case .detail(_, false) = viewedRoute else { fatalError("저장 이후는 상세로 이동") }
            router.pop()
            let commentRoute = router.showAnalysis(entry, showComments: true)
            guard case .detail(_, true) = commentRoute else { fatalError("댓글 알림은 확장 상태를 전달") }
            let another = entries.first!
            precondition(!another.hasViewedAnalysis, "다른 경기는 준비 상태를 유지한다")
            // 쿼터가 추가되면 새 쿼터의 설정도 확인해야 한다.
            entry.records[1].hasViewedAnalysis = false
            precondition(!entry.hasViewedAnalysis)
            entry.records[1].hasViewedAnalysis = true
            try context.save()
            let stalePathCount = router.paths[.home]!.count
            router.pushAnalysis(.ready(another), in: .home)
            router.finishAnalysis(entry, in: .home, expectedPathCount: stalePathCount)
            precondition(router.paths[.home]?.count == stalePathCount + 1,
                         "로딩 중 다른 경로가 쌓였다면 스택을 변경하지 않아야 한다")
            print("PASS: 경기 묶음·첫 진입/재진입·댓글 경로·뒤로가기·다른 탭 보호")
        } else {
            let entries = AnalysisEntry.grouped(from: try context.fetch(FetchDescriptor<WorkoutRecord>()))
            precondition(entries.filter(\.hasViewedAnalysis).count == 1,
                         "분석 보기 여부는 프로세스 재시작 이후에도 남아야 한다")
            print("PASS: 분석 보기 상태의 디스크 영속화")
        }
    }

}
