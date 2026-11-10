import SwiftUI

struct AnalysisRouteDestinations: ViewModifier {
    let tab: AppRouter.AppTab

    func body(content: Content) -> some View {
        content.navigationDestination(for: AnalysisRoute.self) { route in
            switch route {
            case .ready(let entry):
                ReadyForDetailView(entry: entry, navigationTab: tab)
            case .analyzing(let entry):
                AnalyzingView(entry: entry, navigationTab: tab)
            case .detail(let entry, let showComments):
                AnalysisDetailView(entry: entry, showComments: showComments)
            }
        }
    }
}
