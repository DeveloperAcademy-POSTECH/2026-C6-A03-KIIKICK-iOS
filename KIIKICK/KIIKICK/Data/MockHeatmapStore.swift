import Foundation
import Observation

@MainActor @Observable
final class MockHeatmapStore {
    private(set) var match: MockHeatmapMatch
    private(set) var position: MockHeatmapPosition
    private(set) var statusMessage: String?

    init() {
        let currentPosition = UserSession.mockHeatmapPosition
        position = currentPosition
        match = MockHeatmapGenerator.makeAll(seed: 102)
    }

    func regenerate() {
        match = MockHeatmapGenerator.makeAll(seed: match.seed + 1)
        statusMessage = "새 목업 데이터를 만들었습니다."
    }

    func syncPosition() {
        let currentPosition = UserSession.mockHeatmapPosition
        guard currentPosition != position else { return }
        position = currentPosition
        statusMessage = "포지션별 3개 목업 데이터를 표시합니다. 현재 계정: \(position.displayName)"
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(match)
            let url = URL.documentsDirectory.appending(path: "mock-heatmap-\(match.seed).json")
            try data.write(to: url, options: .atomic)
            statusMessage = "저장 완료: \(url.lastPathComponent)"
        } catch {
            statusMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
}
