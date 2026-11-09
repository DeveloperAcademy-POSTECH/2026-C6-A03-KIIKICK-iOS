import Foundation

@main
struct OverallCalculatorChecks {
    static func main() {
        let date = Date(timeIntervalSince1970: 1_793_491_200)
        func workout(
            duration: Double = 900, distance: Double = 1500, speed: Double = 25,
            accelerations: Int = 15, decelerations: Int = 15, offset: Double = 0
        ) -> OverallWorkout {
            OverallWorkout(
                date: date.addingTimeInterval(offset), durationSeconds: duration,
                distanceMeters: distance, peakSpeedKmh: speed,
                accelerationCount: accelerations, decelerationCount: decelerations, calories: 200
            )
        }

        let baseline = OverallCalculator.history(from: [workout()])
        precondition(baseline.current?.score == 95, "기준 성능은 95점")
        precondition(baseline.delta == nil, "첫 기록에는 증감이 없음")
        precondition(OverallCalculator.history(from: []).current == nil)
        precondition(OverallCalculator.history(from: [workout(duration: 0)]).current == nil)
        precondition(OverallCalculator.history(from: [workout(distance: .nan)]).current == nil)

        let stationary = workout(distance: 0, speed: 0, accelerations: 0, decelerations: 0)
        precondition(OverallCalculator.history(from: [stationary]).current?.score == 0)
        let doublePerformance = workout(distance: 3000, speed: 50, accelerations: 30, decelerations: 30)
        precondition(OverallCalculator.history(from: [doublePerformance]).current?.score == 144,
                     "100점으로 제한하지 않고 공식을 적용")

        let weighted = OverallCalculator.history(from: [
            workout(duration: 60, distance: 100, accelerations: 1, decelerations: 1),
            workout(duration: 540, distance: 0, accelerations: 0, decelerations: 0, offset: 600)
        ])
        precondition(weighted.current?.score == 56, "분당 지표는 총 시간으로 가중")
        precondition(abs(weighted.current!.activityRatio - 0.1) < 0.000001)
        precondition(abs(weighted.current!.changeRatio - 0.1) < 0.000001)
        let invalidBenchmark = OverallBenchmark(
            metersPerMinute: 0, peakSpeedKmh: 25, changesPerMinute: 2, accelerationThreshold: 0.5
        )
        precondition(OverallCalculator.history(from: [workout()], benchmark: invalidBenchmark).current == nil)

        let input = OverallWorkoutInput(
            date: date, durationSeconds: 60, distanceMeters: 100, calories: 10,
            samples: [0.0, 1, 2, 2, 1, 0].enumerated().map { index, speed in
                OverallSpeedSample(date: date.addingTimeInterval(Double(index)), metersPerSecond: speed)
            }
        )
        let movement = input.workout()!
        precondition(movement.accelerationCount == 1 && movement.decelerationCount == 1,
                     "연속 가감속은 한 구간으로 집계")
        precondition(abs(movement.peakSpeedKmh - 7.2) < 0.000001, "m/s를 km/h로 변환")
        let missingSamples = OverallWorkoutInput(
            date: date, durationSeconds: 60, distanceMeters: 100, calories: 10, samples: []
        )
        precondition(missingSamples.workout() == nil, "속도 기록 누락을 0점으로 처리하지 않음")

        let mock = OverallCalculator.history(from: OverallMockData.workouts.reversed())
        precondition(mock.current?.score == 106 && mock.delta == 6,
                     "정렬 후 누적 목업 결과와 직전 누적 대비 증감")
        precondition(abs(mock.totalDistanceKm - 7.8) < 0.000001)
        precondition(mock.averageCalories == 225)
        print("PASS: OVR 공식·시간 가중·증감·100점 초과·잘못된 입력·가감속 구간·목업 106(+6)")
    }
}
