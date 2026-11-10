//
//  QuarterFriendsModel.swift
//  KIIKICK
//

import Foundation
import Observation

@MainActor @Observable
final class QuarterFriendsModel {
    private enum Mutation: Equatable {
        case add(QuarterFriendResponse)
        case remove(UUID)
    }

    private struct PendingMutation {
        let mutation: Mutation
        let key: UUID
        let matchVersion: Int
    }

    private(set) var friends: [QuarterFriendResponse] = []
    private(set) var isLoading = false
    private(set) var isMutating = false
    private(set) var errorMessage: String?
    private(set) var matchVersion: Int?

    let matchID: UUID
    let quarterID: UUID
    private let provider: any Provider
    private var hasLoaded = false
    private var pendingMutation: PendingMutation?

    init(matchID: UUID, quarterID: UUID, provider: (any Provider)? = nil) {
        self.matchID = matchID
        self.quarterID = quarterID
        self.provider = provider ?? NetworkService.provider
    }

    var profiles: [UserProfile] {
        friends.map {
            UserProfile(id: $0.userId, nickname: $0.nickname, status: .friend, avatarUrl: $0.avatarUrl)
        }
    }

    var canMutate: Bool {
        matchVersion != nil && !isLoading && !isMutating
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
                with: QuarterFriendEndpoints.list(matchID: matchID, quarterID: quarterID)
            )
            try Task.checkCancellation()
            friends = unique(response.data)
            matchVersion = response.meta.matchVersion
            pendingMutation = nil
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            clearOnAccessLoss(error)
            errorMessage = "함께 뛴 친구를 불러오지 못했어요. 다시 시도해 주세요"
        }
    }

    func add(_ profile: UserProfile) async -> Bool {
        await change(.add(QuarterFriendResponse(profile: profile)))
    }

    func remove(friendUserID: UUID) async -> Bool {
        await change(.remove(friendUserID))
    }

    private func change(_ mutation: Mutation) async -> Bool {
        guard !isMutating else { return false }
        if matchVersion == nil {
            await reload()
        }
        guard let currentVersion = matchVersion else { return false }

        if pendingMutation?.mutation != mutation {
            pendingMutation = PendingMutation(
                mutation: mutation,
                key: UUID(),
                matchVersion: currentVersion
            )
        }
        guard let pendingMutation else { return false }

        isMutating = true
        errorMessage = nil
        defer { isMutating = false }

        do {
            let endpoint: Endpoint<Void>
            switch mutation {
            case .add(let friend):
                endpoint = QuarterFriendEndpoints.add(
                    matchID: matchID,
                    quarterID: quarterID,
                    friendUserID: friend.userId,
                    matchVersion: pendingMutation.matchVersion,
                    idempotencyKey: pendingMutation.key
                )
            case .remove(let friendUserID):
                endpoint = QuarterFriendEndpoints.remove(
                    matchID: matchID,
                    quarterID: quarterID,
                    friendUserID: friendUserID,
                    matchVersion: pendingMutation.matchVersion,
                    idempotencyKey: pendingMutation.key
                )
            }
            try await provider.requestWithoutResponse(with: endpoint)
            try Task.checkCancellation()
            apply(mutation)
            matchVersion = pendingMutation.matchVersion + 1
            self.pendingMutation = nil
            return true
        } catch {
            guard !Task.isCancelled else { return false }
            if case NetworkError.invalidHttpStatusCode(412, _) = error {
                self.pendingMutation = nil
                matchVersion = nil
                hasLoaded = false
                await reload()
                errorMessage = "다른 변경사항을 반영했어요. 다시 시도해 주세요"
            } else {
                clearOnAccessLoss(error)
                errorMessage = "함께 뛴 친구를 변경하지 못했어요. 다시 시도해 주세요"
            }
            return false
        }
    }

    private func apply(_ mutation: Mutation) {
        switch mutation {
        case .add(let friend):
            if !friends.contains(where: { $0.userId == friend.userId }) {
                friends.append(friend)
            }
        case .remove(let friendUserID):
            friends.removeAll { $0.userId == friendUserID }
        }
    }

    private func unique(_ values: [QuarterFriendResponse]) -> [QuarterFriendResponse] {
        var seen = Set<UUID>()
        return values.filter { seen.insert($0.userId).inserted }
    }

    private func clearOnAccessLoss(_ error: Error) {
        if case let NetworkError.invalidHttpStatusCode(status, _) = error, [403, 404].contains(status) {
            friends = []
            matchVersion = nil
            pendingMutation = nil
            hasLoaded = false
        }
    }
}
