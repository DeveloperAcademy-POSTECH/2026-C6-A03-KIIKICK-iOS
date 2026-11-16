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
        match = MockHeatmapGenerator.make(seed: 102, position: currentPosition)
    }

    func regenerate() {
        match = MockHeatmapGenerator.make(seed: match.seed + 1, position: position)
        statusMessage = "새 목업 데이터를 만들었습니다."
    }

    func syncPosition() {
        let currentPosition = UserSession.mockHeatmapPosition
        guard currentPosition != position else { return }
        position = currentPosition
        match = MockHeatmapGenerator.make(seed: match.seed, position: position)
        statusMessage = "\(position.displayName) 포지션을 적용했습니다."
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
