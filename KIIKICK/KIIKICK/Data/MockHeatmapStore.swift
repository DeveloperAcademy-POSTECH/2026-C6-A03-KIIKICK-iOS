import Foundation
import Observation

@MainActor @Observable
final class MockHeatmapStore {
    private(set) var match: MockHeatmapMatch
    private(set) var theme: MockHeatmapTheme
    private(set) var statusMessage: String?

    init() {
        let currentTheme = UserSession.mockHeatmapTheme
        theme = currentTheme
        match = MockHeatmapGenerator.make(seed: 102, theme: currentTheme)
    }

    func regenerate() {
        match = MockHeatmapGenerator.make(seed: match.seed + 1, theme: theme)
        statusMessage = "새 목업 데이터를 만들었습니다."
    }

    func syncTheme() {
        let currentTheme = UserSession.mockHeatmapTheme
        guard currentTheme != theme else { return }
        theme = currentTheme
        match = MockHeatmapGenerator.make(seed: match.seed, theme: theme)
        statusMessage = "\(theme.displayName) 테마를 적용했습니다."
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
