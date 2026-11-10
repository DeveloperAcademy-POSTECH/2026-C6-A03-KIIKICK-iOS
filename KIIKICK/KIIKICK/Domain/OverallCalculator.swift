import Foundation

struct OverallBenchmark {
    let metersPerMinute: Double
    let peakSpeedKmh: Double
    let changesPerMinute: Double
    let accelerationThreshold: Double

    // OVR 계산에 사용하는 기존 임시 기준. 실제 서비스 기준이 정해지면 이 설정만 교체한다.
    static let provisional = OverallBenchmark(
        metersPerMinute: 100, peakSpeedKmh: 25, changesPerMinute: 2,
        accelerationThreshold: 0.5
    )
}

struct OverallWorkout: Equatable {
    let date: Date
    let durationSeconds: Double
    let distanceMeters: Double
    let peakSpeedKmh: Double
    let accelerationCount: Int
    let decelerationCount: Int
    let calories: Double

    var isValid: Bool {
        durationSeconds.isFinite && durationSeconds > 0
            && distanceMeters.isFinite && distanceMeters >= 0
            && peakSpeedKmh.isFinite && peakSpeedKmh >= 0
            && accelerationCount >= 0 && decelerationCount >= 0
            && calories.isFinite && calories >= 0
            && date.timeIntervalSinceReferenceDate.isFinite
    }
}

struct OverallCalculation: Equatable {
    let activityRatio: Double
    let speedRatio: Double
    let changeRatio: Double
    let combinedRatio: Double
    let score: Int
}

struct OverallHistory {
    let workouts: [OverallWorkout]
    let cumulative: [OverallCalculation]

    static let empty = OverallHistory(workouts: [], cumulative: [])
    var current: OverallCalculation? { cumulative.last }
    var delta: Int? {
        guard cumulative.count > 1, let current else { return nil }
        return current.score - cumulative[cumulative.count - 2].score
    }
    var totalDistanceKm: Double { workouts.reduce(0) { $0 + $1.distanceMeters } / 1000 }
    var averageCalories: Int {
        guard !workouts.isEmpty else { return 0 }
        return Int((workouts.reduce(0) { $0 + $1.calories } / Double(workouts.count)).rounded())
    }
}

enum OverallCalculator {
    static func history(
        from workouts: [OverallWorkout], benchmark: OverallBenchmark = .provisional
    ) -> OverallHistory {
        guard [benchmark.metersPerMinute, benchmark.peakSpeedKmh, benchmark.changesPerMinute]
            .allSatisfy({ $0.isFinite && $0 > 0 }) else { return .empty }

        let sorted = workouts.filter(\.isValid).sorted { $0.date < $1.date }
        var duration = 0.0, distance = 0.0, speedSum = 0.0, changes = 0.0
        var cumulative: [OverallCalculation] = []
        for (index, workout) in sorted.enumerated() {
            duration += workout.durationSeconds
            distance += workout.distanceMeters
            speedSum += workout.peakSpeedKmh
            changes += Double(workout.accelerationCount) + Double(workout.decelerationCount)
            let minutes = duration / 60
            // 분당 지표는 전체 시간으로 가중하고, 대표 최고속도는 쿼터별 최고속도의 평균이다.
            let activity = (distance / minutes) / benchmark.metersPerMinute
            let speed = (speedSum / Double(index + 1)) / benchmark.peakSpeedKmh
            let change = (changes / minutes) / benchmark.changesPerMinute
            let combined = activity * 0.45 + speed * 0.35 + change * 0.20
            let rawScore = (95 * pow(combined, 0.6)).rounded()
            guard rawScore.isFinite, rawScore >= 0, rawScore < Double(Int.max) else { return .empty }
            // 100점 초과도 공식 그대로 유지한다. ProfileRingView의 Overdrive 표시와 연결된다.
            cumulative.append(OverallCalculation(
                activityRatio: activity, speedRatio: speed, changeRatio: change,
                combinedRatio: combined, score: Int(rawScore)
            ))
        }
        return OverallHistory(workouts: sorted, cumulative: cumulative)
    }
}

struct OverallSpeedSample: Equatable {
    let date: Date
    let metersPerSecond: Double
}

struct OverallWorkoutInput: Equatable {
    let date: Date
    let durationSeconds: Double
    let distanceMeters: Double
    let calories: Double
    let samples: [OverallSpeedSample]

    func workout(benchmark: OverallBenchmark = .provisional) -> OverallWorkout? {
        let end = date.addingTimeInterval(durationSeconds)
        let valid = samples.filter {
            $0.metersPerSecond.isFinite && $0.metersPerSecond >= 0
                && $0.date >= date && $0.date <= end
        }.sorted { $0.date < $1.date }
        // GPS/속도 기록이 없으면 0점으로 간주하지 않고 OVR 산정에서 제외한다.
        guard !valid.isEmpty, benchmark.accelerationThreshold.isFinite,
              benchmark.accelerationThreshold > 0 else { return nil }
        var accelerations = 0, decelerations = 0, previousDirection = 0
        for (previous, current) in zip(valid, valid.dropFirst()) {
            let seconds = current.date.timeIntervalSince(previous.date)
            guard seconds > 0 else { continue }
            let acceleration = (current.metersPerSecond - previous.metersPerSecond) / seconds
            let direction = acceleration > benchmark.accelerationThreshold ? 1
                : (acceleration < -benchmark.accelerationThreshold ? -1 : 0)
            // 연속된 같은 방향 가감속은 한 구간으로 센다. 쿼터 사이의 휴식은 연결하지 않는다.
            if direction != previousDirection {
                if direction == 1 { accelerations += 1 }
                if direction == -1 { decelerations += 1 }
            }
            previousDirection = direction
        }
        return OverallWorkout(
            date: date, durationSeconds: durationSeconds, distanceMeters: distanceMeters,
            peakSpeedKmh: (valid.map(\.metersPerSecond).max() ?? 0) * 3.6,
            accelerationCount: accelerations, decelerationCount: decelerations, calories: calories
        )
    }
}
