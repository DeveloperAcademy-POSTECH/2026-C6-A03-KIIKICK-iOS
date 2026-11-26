import Foundation

struct MockHeatmapQuarter: Codable, Hashable, Identifiable {
    let number: Int
    let duration: TimeInterval
    let points: [MockHeatmapPoint]
    let events: [MockHeatmapEvent]
    /// 4쿼터에서 의도적으로 반대 공격 방향을 보여주기 위한 시연용 플래그.
    let isAttackDirectionReversed: Bool

    var id: Int { number }

    var goalCount: Int {
        events.count(where: { $0.type == .goal })
    }

    var assistCount: Int {
        events.count(where: { $0.type == .assist })
    }

    init(
        number: Int,
        duration: TimeInterval,
        points: [MockHeatmapPoint],
        events: [MockHeatmapEvent],
        isAttackDirectionReversed: Bool = false
    ) {
        self.number = number
        self.duration = duration
        self.points = points
        self.events = events
        self.isAttackDirectionReversed = isAttackDirectionReversed
    }

    private enum CodingKeys: String, CodingKey {
        case number, duration, points, events, isAttackDirectionReversed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        points = try container.decode([MockHeatmapPoint].self, forKey: .points)
        events = try container.decode([MockHeatmapEvent].self, forKey: .events)
        isAttackDirectionReversed = try container.decodeIfPresent(Bool.self, forKey: .isAttackDirectionReversed) ?? false
    }
}
