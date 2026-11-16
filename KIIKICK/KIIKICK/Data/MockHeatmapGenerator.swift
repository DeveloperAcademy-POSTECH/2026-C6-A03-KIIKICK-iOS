import Foundation

enum MockHeatmapGenerator {
    private static let fieldLength = 105.0
    private static let fieldWidth = 68.0
    static let quarterDuration: TimeInterval = 15 * 60
    private static let secondsPerPoint: TimeInterval = 5
    private static let mockSprintCount = 4
    private static let mockSprintDistanceMeters = 24.0
    private static let mockSprintBaseSpeedMps = 7.35
    private static let mockSprintSpeedVariationMps = 0.55
    private static let maximumSpeedMps = 29.0 / 3.6

    private struct Anchor {
        let x: Double
        let y: Double
        let weight: Double
    }

    private struct Profile {
        let id: String
        let displayName: String
        let role: String
        let anchors: [Anchor]
        let movementNoise: Double
        let cruisingSpeedMps: Double
        let maxSpeedMps: Double
        let restingHeartRate: Double
        let peakHeartRate: Double
        let goalsPerQuarter: Int
        let assistsPerQuarter: Int
    }

    private struct SeededRandom {
        private var state: UInt64

        init(seed: Int) {
            state = UInt64(bitPattern: Int64(seed)) ^ 0x9E3779B97F4A7C15
        }

        mutating func unit() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            return Double(state >> 11) / Double(1 << 53)
        }

        mutating func normal(mean: Double = 0, standardDeviation: Double) -> Double {
            let first = max(unit(), 0.000_001)
            let second = unit()
            return mean + sqrt(-2 * log(first)) * cos(2 * .pi * second) * standardDeviation
        }
    }

    private static let profiles: [Profile] = [
        Profile(
            id: "son-heung-min",
            displayName: "손흥민 (공격수 스타일 목업)",
            role: "전방·측면 공격수",
            anchors: [
                Anchor(x: 0.74, y: 0.29, weight: 0.28),
                Anchor(x: 0.84, y: 0.50, weight: 0.42),
                Anchor(x: 0.72, y: 0.73, weight: 0.20),
                Anchor(x: 0.59, y: 0.40, weight: 0.10),
            ],
            movementNoise: 0.026,
            cruisingSpeedMps: 1.85,
            maxSpeedMps: 8.8,
            restingHeartRate: 118,
            peakHeartRate: 184,
            goalsPerQuarter: 3,
            assistsPerQuarter: 1
        ),
        Profile(
            id: "lee-kang-in",
            displayName: "이강인 (플레이메이커 스타일 목업)",
            role: "공격형 미드필더",
            anchors: [
                Anchor(x: 0.52, y: 0.32, weight: 0.24),
                Anchor(x: 0.65, y: 0.50, weight: 0.34),
                Anchor(x: 0.73, y: 0.71, weight: 0.24),
                Anchor(x: 0.46, y: 0.68, weight: 0.18),
            ],
            movementNoise: 0.022,
            cruisingSpeedMps: 1.70,
            maxSpeedMps: 8.0,
            restingHeartRate: 114,
            peakHeartRate: 180,
            goalsPerQuarter: 1,
            assistsPerQuarter: 3
        ),
        Profile(
            id: "kim-min-jae",
            displayName: "김민재 (센터백 스타일 목업)",
            role: "센터백",
            anchors: [
                Anchor(x: 0.21, y: 0.38, weight: 0.30),
                Anchor(x: 0.29, y: 0.55, weight: 0.40),
                Anchor(x: 0.22, y: 0.72, weight: 0.20),
                Anchor(x: 0.40, y: 0.50, weight: 0.10),
            ],
            movementNoise: 0.016,
            cruisingSpeedMps: 1.45,
            maxSpeedMps: 7.5,
            restingHeartRate: 108,
            peakHeartRate: 172,
            goalsPerQuarter: 0,
            assistsPerQuarter: 1
        ),
    ]

    static func make(seed: Int) -> MockHeatmapMatch {
        make(seed: seed, position: UserSession.mockHeatmapPosition)
    }

    static func make(seed: Int, position: MockHeatmapPosition) -> MockHeatmapMatch {
        return make(seed: seed, position: position, start: nil)
    }

    static func make(
        seed: Int,
        position: MockHeatmapPosition,
        start: Date?
    ) -> MockHeatmapMatch {
        let defaultStart = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 11,
            day: 16,
            hour: 10
        ).date ?? .now
        let start = start ?? defaultStart

        let profile = profiles.first(where: { $0.id == position.rawValue }) ?? profiles[0]
        let players = [makePlayer(profile, seed: seed, start: start)]

        return MockHeatmapMatch(
            id: "mock-match-\(seed)",
            seed: seed,
            startedAt: start,
            quarterDuration: quarterDuration,
            secondsPerPoint: secondsPerPoint,
            players: players
        )
    }

    private static func makePlayer(_ profile: Profile, seed: Int, start: Date) -> MockHeatmapPlayer {
        let quarters = (1...4).map { quarterNumber in
            let quarterStart = start.addingTimeInterval(Double(quarterNumber - 1) * quarterDuration)
            var random = SeededRandom(seed: seed + quarterNumber * 10_007)
            let points = makePoints(
                profile,
                quarterNumber: quarterNumber,
                start: quarterStart,
                random: &random
            )
            let events = makeEvents(
                profile,
                quarterNumber: quarterNumber,
                points: points,
                random: &random
            )
            return MockHeatmapQuarter(number: quarterNumber, duration: quarterDuration, points: points, events: events)
        }

        return MockHeatmapPlayer(
            id: profile.id,
            displayName: profile.displayName,
            role: profile.role,
            quarters: quarters
        )
    }

    private static func makePoints(
        _ profile: Profile,
        quarterNumber: Int,
        start: Date,
        random: inout SeededRandom
    ) -> [MockHeatmapPoint] {
        var anchor = weightedAnchor(from: profile.anchors, random: &random)
        var x = clamp(anchor.x + random.normal(standardDeviation: 0.012), 0.02, 0.98)
        var y = clamp(anchor.y + random.normal(standardDeviation: 0.012), 0.02, 0.98)
        var previousX = x
        var previousY = y
        var points: [MockHeatmapPoint] = []
        let pointCount = Int(quarterDuration / secondsPerPoint)

        for index in 0...pointCount {
            if random.unit() < 0.12 {
                anchor = weightedAnchor(from: profile.anchors, random: &random)
            }

            let progress = Double(index) / Double(max(pointCount, 1))
            let fatigue = 1 - 0.12 * progress
            let targetAngle = atan2(anchor.y - y, anchor.x - x)
            let direction = targetAngle + random.normal(standardDeviation: 0.68)
            var desiredSpeed = profile.cruisingSpeedMps * (0.88 + 0.18 * fatigue)
            desiredSpeed += random.normal(standardDeviation: profile.movementNoise * 3.0)

            x += cos(direction) * desiredSpeed * secondsPerPoint / fieldLength
            y += sin(direction) * desiredSpeed * secondsPerPoint / fieldWidth
            x += random.normal(standardDeviation: profile.movementNoise)
            y += random.normal(standardDeviation: profile.movementNoise)
            x = clamp(x, 0.02, 0.98)
            y = clamp(y, 0.02, 0.98)

            let distanceMeters = hypot((x - previousX) * fieldLength, (y - previousY) * fieldWidth)
            let speedMps = min(profile.maxSpeedMps, distanceMeters / secondsPerPoint)
            let intensity = clamp(speedMps / profile.maxSpeedMps, 0, 1)
            var heartRate = profile.restingHeartRate +
                (profile.peakHeartRate - profile.restingHeartRate) * (0.18 + 0.72 * intensity + 0.10 * progress)
            heartRate += random.normal(standardDeviation: 2.2)

            let timestamp = start.addingTimeInterval(Double(index) * secondsPerPoint)
            points.append(
                MockHeatmapPoint(
                    id: "\(profile.id)-q\(quarterNumber)-p\(index)",
                    timestamp: timestamp,
                    xMeters: x * fieldLength,
                    yMeters: y * fieldWidth,
                    normalizedX: x,
                    normalizedY: y,
                    speedMps: speedMps,
                    heartRateBpm: clamp(heartRate, profile.restingHeartRate, profile.peakHeartRate)
                )
            )
            previousX = x
            previousY = y
        }

        let sprintSpeed = variedSprintSpeed(for: profile, random: &random)
        return addingAttackDirectionSprints(to: points, profile: profile, sprintSpeed: sprintSpeed)
    }

    /// 스프린트 속도를 경기/쿼터마다 조금씩 흔들되, 화면에 표시되는 최고 속도는 29km/h를 넘기지 않는다.
    private static func variedSprintSpeed(
        for profile: Profile,
        random: inout SeededRandom
    ) -> Double {
        let roleOffset: Double
        switch profile.id {
        case MockHeatmapPosition.attacker.rawValue:
            roleOffset = 0.25
        case MockHeatmapPosition.defender.rawValue:
            roleOffset = -0.20
        default:
            roleOffset = 0
        }
        let speed = mockSprintBaseSpeedMps + roleOffset +
            random.normal(standardDeviation: mockSprintSpeedVariationMps)
        let profileMaximum = min(profile.maxSpeedMps, maximumSpeedMps)
        return clamp(speed, 6.1, profileMaximum)
    }

    /// 목업 타임라인의 스프린트 탭을 항상 확인할 수 있도록 쿼터마다 네 구간을 만든다.
    /// 공격수는 공격 방향(x 증가)으로만 달리고, 미드필더·수비수는 전환/수비 복귀를
    /// 표현하기 위해 절반의 구간을 반대 방향(x 감소)으로 달린다.
    /// 스프린트 사이에는 일반 속도 포인트를 둬 `SprintDetector`가 각각 별도 구간으로
    /// 인식하도록 한다.
    private static func addingAttackDirectionSprints(
        to points: [MockHeatmapPoint],
        profile: Profile,
        sprintSpeed: Double
    ) -> [MockHeatmapPoint] {
        guard points.count > mockSprintCount * 3 else { return points }

        var result = points
        let lastStartIndex = points.count - 2
        let spacing = max(1, lastStartIndex / (mockSprintCount + 1))
        let startIndexes = (1...mockSprintCount).map { min(lastStartIndex - 1, $0 * spacing) }

        for (sprintIndex, startIndex) in startIndexes.enumerated() {
            let endIndex = startIndex + 1
            let originalStart = points[startIndex]
            let originalEnd = points[endIndex]
            let isReverseSprint = profile.id != MockHeatmapPosition.attacker.rawValue && sprintIndex.isMultiple(of: 2)
            let direction = isReverseSprint ? -1.0 : 1.0
            let startX: Double
            if isReverseSprint {
                startX = clamp(originalStart.xMeters, mockSprintDistanceMeters + 2, fieldLength - 4)
            } else {
                startX = clamp(originalStart.xMeters, 4, fieldLength - mockSprintDistanceMeters - 2)
            }
            let endX = startX + direction * mockSprintDistanceMeters
            let laneDrift = sprintIndex.isMultiple(of: 2) ? -2.5 : 2.5
            let startY = clamp(originalStart.yMeters, 3, fieldWidth - 3)
            let endY = clamp(startY + laneDrift, 3, fieldWidth - 3)
            let speed = min(profile.maxSpeedMps, sprintSpeed)

            result[startIndex] = sprintPoint(
                basedOn: originalStart,
                xMeters: startX,
                yMeters: startY,
                speedMps: speed
            )
            result[endIndex] = sprintPoint(
                basedOn: originalEnd,
                xMeters: endX,
                yMeters: endY,
                speedMps: speed
            )
        }

        return result
    }

    private static func sprintPoint(
        basedOn point: MockHeatmapPoint,
        xMeters: Double,
        yMeters: Double,
        speedMps: Double
    ) -> MockHeatmapPoint {
        MockHeatmapPoint(
            id: point.id,
            timestamp: point.timestamp,
            xMeters: xMeters,
            yMeters: yMeters,
            normalizedX: xMeters / fieldLength,
            normalizedY: yMeters / fieldWidth,
            speedMps: speedMps,
            heartRateBpm: point.heartRateBpm
        )
    }

    private static func makeEvents(
        _ profile: Profile,
        quarterNumber: Int,
        points: [MockHeatmapPoint],
        random: inout SeededRandom
    ) -> [MockHeatmapEvent] {
        guard !points.isEmpty else { return [] }
        let goals = variedCount(around: profile.goalsPerQuarter, random: &random)
        let assists = variedCount(around: profile.assistsPerQuarter, random: &random)
        let eventCount = goals + assists
        let lowerBound = min(2, max(0, points.count - 1))
        let upperBound = max(lowerBound, points.count - 3)
        var indexes: Set<Int> = []

        while indexes.count < min(eventCount, upperBound - lowerBound + 1) {
            let index = lowerBound + Int(random.unit() * Double(upperBound - lowerBound + 1))
            indexes.insert(min(upperBound, index))
        }

        let sortedIndexes = indexes.sorted()
        let types = Array(repeating: MockHeatmapEventType.goal, count: goals) +
            Array(repeating: MockHeatmapEventType.assist, count: assists)
        return sortedIndexes.enumerated().map { index, pointIndex in
            MockHeatmapEvent(
                id: "\(profile.id)-q\(quarterNumber)-event\(index)",
                type: types[index],
                pointIndex: pointIndex,
                timestamp: points[pointIndex].timestamp
            )
        }
    }

    /// 프로필 수치는 쿼터당 평균값으로 사용하고, 실제 표시 이벤트 수는 쿼터마다 한 단계씩 흔든다.
    /// 공격수 3골·미드필더 3어시 같은 패턴이 매 쿼터 반복되지 않도록 한다.
    private static func variedCount(around target: Int, random: inout SeededRandom) -> Int {
        guard target > 0 else { return 0 }
        let roll = random.unit()
        if roll < 0.30 { return max(0, target - 1) }
        if roll > 0.70 { return target + 1 }
        return target
    }

    private static func weightedAnchor(from anchors: [Anchor], random: inout SeededRandom) -> Anchor {
        let total = anchors.map(\.weight).reduce(0, +)
        var value = random.unit() * total
        for anchor in anchors {
            value -= anchor.weight
            if value <= 0 { return anchor }
        }
        return anchors.last ?? Anchor(x: 0.5, y: 0.5, weight: 1)
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        max(lower, min(upper, value))
    }
}
