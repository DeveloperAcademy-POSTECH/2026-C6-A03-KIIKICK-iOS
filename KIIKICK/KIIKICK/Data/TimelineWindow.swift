import Foundation

/// 슬라이더가 가리키는 시각까지의 최근 20초 구간. 쿼터 시작과 끝을 벗어나지 않는다.
/// DESIGN-GAP: #69는 선택 시각의 앞/뒤 중 어느 쪽 20초인지 지정하지 않아 직전 구간으로 해석한다.
struct TimelineWindow {
    static let length: TimeInterval = 20

    let start: Date
    let end: Date

    init(quarterStart: Date, duration: TimeInterval, elapsed: TimeInterval) {
        let clampedElapsed = min(max(0, elapsed), max(0, duration))
        start = quarterStart.addingTimeInterval(max(0, clampedElapsed - Self.length))
        end = quarterStart.addingTimeInterval(clampedElapsed)
    }

    func contains(_ timestamp: Date) -> Bool {
        start <= timestamp && timestamp <= end
    }
}
