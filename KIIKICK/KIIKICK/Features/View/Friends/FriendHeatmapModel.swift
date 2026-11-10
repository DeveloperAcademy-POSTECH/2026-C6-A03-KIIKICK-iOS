//
//  FriendHeatmapModel.swift
//  KIIKICK
//

import Foundation
import Observation

@MainActor @Observable
final class FriendHeatmapModel {
    private(set) var heatmap: FriendHeatmapResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    let userID: UUID
    let matchID: UUID
    let quarterID: UUID
    private let provider: any Provider
    private var hasLoaded = false

    init(userID: UUID, matchID: UUID, quarterID: UUID, provider: (any Provider)? = nil) {
        self.userID = userID
        self.matchID = matchID
        self.quarterID = quarterID
        self.provider = provider ?? NetworkService.provider
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await provider.request(
                with: FriendMatchEndpoints.heatmap(userID: userID, matchID: matchID, quarterID: quarterID)
            )
            try Task.checkCancellation()
            guard response.data.quarterId == quarterID else { throw NetworkError.decodeError }
            heatmap = response.data
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            heatmap = nil
            errorMessage = "친구의 히트맵을 불러오지 못했어요"
        }
    }
}
