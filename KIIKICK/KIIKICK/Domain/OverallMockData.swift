#if DEBUG
import Foundation

enum OverallMockData {
    static let enabledKey = "debug.ovr.useMockData"

    // 결정적인 입력을 사용해 공식·증감·100점 초과 표시를 재현한다. SwiftData에 저장하지 않는다.
    static let workouts: [OverallWorkout] = {
        let firstDate = Date(timeIntervalSince1970: 1_793_491_200)
        return zip([1500.0, 1800, 2100, 2400], [22.0, 26, 28, 32]).enumerated().map { index, values in
            OverallWorkout(
                date: firstDate.addingTimeInterval(Double(index) * 86400),
                durationSeconds: 15 * 60, distanceMeters: values.0, peakSpeedKmh: values.1,
                accelerationCount: 10 + index * 5, decelerationCount: 10 + index * 5,
                calories: 180 + Double(index) * 30
            )
        }
    }()
}
#endif
