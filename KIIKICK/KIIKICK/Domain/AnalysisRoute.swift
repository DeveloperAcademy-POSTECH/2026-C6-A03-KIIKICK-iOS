enum AnalysisRoute: Hashable {
    case ready(AnalysisEntry)
    case analyzing(AnalysisEntry)
    case detail(AnalysisEntry, showComments: Bool = false)
}
