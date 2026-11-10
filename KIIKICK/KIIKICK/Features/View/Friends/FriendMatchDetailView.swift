import SwiftUI

struct FriendMatchDetailView: View {
    let userID: UUID
    let matchID: UUID
    let nickname: String
    @State private var analysis: FriendMatchAnalysis?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let analysis {
                AnalysisDetailView(
                    entry: analysis.entry,
                    friendNickname: nickname,
                    matchID: matchID,
                    friendUserID: userID
                )
            } else if isLoading {
                ProgressView()
            } else {
                VStack(spacing: 16) {
                    Text(errorMessage ?? "아직 공개된 분석 결과가 없어요").textStyle(.body4R).foregroundStyle(.gray400)
                    CtaView(text: "다시 불러오기", type: .secondary, size: .small) { Task { await load() } }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray950)
        .toolbar(.hidden, for: .tabBar)
        .task(id: matchID) { await load() }
    }
    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let value = try await FriendMatchLoader.load(userID: userID, matchID: matchID, provider: NetworkService.provider)
            try Task.checkCancellation()
            analysis = value
        } catch {
            guard !Task.isCancelled else { return }
            analysis = nil
            errorMessage = "경기를 불러올 수 없어요. 삭제되었거나 친구 관계가 변경되었을 수 있어요"
        }
    }
}
