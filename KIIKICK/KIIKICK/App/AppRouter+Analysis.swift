import SwiftUI

extension AppRouter {
    enum NotificationRoute: Hashable {
        case list
    }

    func showNotifications(in tab: AppTab? = nil) {
        let target = tab ?? selection
        selection = target
        paths[target, default: .init()].append(NotificationRoute.list)
    }

    @discardableResult
    func showAnalysis(_ entry: AnalysisEntry, showComments: Bool = false, in tab: AppTab? = nil) -> AnalysisRoute {
        let route: AnalysisRoute = showComments || entry.hasViewedAnalysis
            ? .detail(entry, showComments: showComments) : .ready(entry)
        pushAnalysis(route, in: tab)
        return route
    }

    func pushAnalysis(_ route: AnalysisRoute, in tab: AppTab? = nil) {
        let target = tab ?? selection
        selection = target
        paths[target, default: .init()].append(route)
    }

    /// 준비·분석 중 화면만 교체하고, 알림 목록 등 이전 스택을 유지한다.
    func finishAnalysis(_ entry: AnalysisEntry, in tab: AppTab, expectedPathCount: Int) {
        guard var path = paths[tab], path.count == expectedPathCount, path.count >= 2 else { return }
        path.removeLast(2)
        path.append(AnalysisRoute.detail(entry))
        paths[tab] = path
    }
}
