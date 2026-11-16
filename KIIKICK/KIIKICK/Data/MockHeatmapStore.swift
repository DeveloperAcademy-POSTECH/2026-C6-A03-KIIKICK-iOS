import Foundation
import Observation

@MainActor @Observable
final class MockHeatmapStore {
    private(set) var match: MockHeatmapMatch
    private(set) var statusMessage: String?

    init() {
        match = MockHeatmapGenerator.make(seed: 102)
    }

    func regenerate() {
        match = MockHeatmapGenerator.make(seed: match.seed + 1)
        statusMessage = "새 목업 데이터를 만들었습니다."
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
