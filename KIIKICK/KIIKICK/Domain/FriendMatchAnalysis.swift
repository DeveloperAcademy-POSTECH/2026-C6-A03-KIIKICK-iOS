import Foundation

struct FriendMatchAnalysis: Identifiable, Hashable {
    let entry: AnalysisEntry
    var id: UUID { entry.id }

    init?(result: MatchResultResponse, quarters: [QuarterResultResponse]) {
        // 분석 보기에서 포지션과 운동 데이터를 제출한 완료 경기만 노출한다.
        guard result.match.status == .completed, result.quarterCount > 0,
              quarters.count == result.quarterCount,
              Set(quarters.map { $0.quarter.id }).count == quarters.count,
              quarters.allSatisfy({ $0.quarter.matchId == result.match.id && $0.quarter.status == .completed
                  && $0.position != nil && $0.workout != nil }) else { return nil }
        let sorted = quarters.sorted { $0.quarter.number < $1.quarter.number }
        let analysisQuarters = sorted.map { value in
            let summary = value.summary.flatMap { [.ready, .partial].contains($0.calculationStatus) ? $0 : nil }
            var quarter = AnalysisQuarter(id: value.quarter.id, quarterNumber: value.quarter.number,
                durationText: Self.duration(summary?.durationSeconds ?? value.workout.map { $0.endDate.timeIntervalSince($0.startDate) }),
                position: value.position?.positionCode,
                field: value.workout?.field.map(Self.field),
                totalDistanceKm: (summary?.totalDistanceM ?? value.workout?.totalDistance ?? 0) / 1000,
                totalCaloriesKcal: summary?.totalCaloriesKcal ?? value.workout?.totalCalories ?? 0)
            quarter.resultStats = Self.stats(speed: summary?.maxSpeedMps.map { $0 * 3.6 },
                distance: (summary?.totalDistanceM ?? value.workout?.totalDistance).map { $0 / 1000 },
                calories: summary?.totalCaloriesKcal ?? value.workout?.totalCalories)
            quarter.resultSections = Self.sections(summary)
            quarter.resultGoals = value.stats?.goals ?? value.workout?.events.map { $0.count { $0.type == "goal" } }
            quarter.resultAssists = value.stats?.assists ?? value.workout?.events.map { $0.count { $0.type == "assist" } }
            return quarter
        }
        let speeds = sorted.map { value -> Double? in
            guard let summary = value.summary, [.ready, .partial].contains(summary.calculationStatus) else { return nil }
            return summary.maxSpeedMps.map { $0 * 3.6 }
        }
        let stats = Self.stats(speed: Self.maximum(speeds),
            distance: Self.sum(sorted.map { $0.workout?.totalDistance }).map { $0 / 1000 },
            calories: Self.sum(sorted.map { $0.workout?.totalCalories }))
        let date = result.match.startedAt ?? result.match.scheduledAt ?? result.match.createdAt
        let title = date.formatted(.dateTime.month().day())
        entry = AnalysisEntry(id: result.match.id, date: date,
            dateAndQuarter: "\(title) • 총 \(analysisQuarters.count)Q",
            fieldName: sorted.compactMap { $0.workout?.field?.name }.first ?? result.match.venueSnapshot?.name ?? "운동장 미지정",
            stats: stats,
            detail: AnalysisDetail(id: result.match.id, title: title, quarters: analysisQuarters, keyStats: stats,
                goalCount: result.goals ?? Self.sum(analysisQuarters.map { $0.resultGoals.map(Double.init) }).map(Int.init),
                assistCount: result.assists ?? Self.sum(analysisQuarters.map { $0.resultAssists.map(Double.init) }).map(Int.init),
                sections: [], disclaimer: "친구의 경기 분석"))
    }

    private static func field(_ payload: WorkoutFieldPayload) -> Field {
        func corner(_ value: WorkoutFieldPayload.Corner) -> FieldCorner {
            FieldCorner(latitude: value.latitude, longitude: value.longitude)
        }
        return Field(name: payload.name, cornerA: corner(payload.cornerA), cornerB: corner(payload.cornerB),
            cornerC: corner(payload.cornerC), cornerD: corner(payload.cornerD),
            rawCornerA: payload.rawCornerA.map(corner), rawCornerB: payload.rawCornerB.map(corner),
            rawCornerC: payload.rawCornerC.map(corner), rawCornerD: payload.rawCornerD.map(corner))
    }
    private static func sum(_ values: [Double?]) -> Double? {
        guard !values.isEmpty, values.allSatisfy({ $0?.isFinite == true }) else { return nil }
        return values.compactMap { $0 }.reduce(0, +)
    }
    private static func maximum(_ values: [Double?]) -> Double? {
        guard values.allSatisfy({ $0?.isFinite == true }) else { return nil }
        return values.compactMap { $0 }.max()
    }
    private static func number(_ value: Double?, digits: Int = 0) -> String {
        guard let value, value.isFinite else { return "—" }
        return value.formatted(.number.grouping(.never).precision(.fractionLength(digits)))
    }
    private static func duration(_ seconds: Double?) -> String {
        guard let seconds, seconds.isFinite, seconds >= 0, seconds < Double(Int.max) else { return "—" }
        let value = Int(seconds)
        return "\(value / 60):\(String(value % 60).leftPaddedToTwoDigits)"
    }
    private static func stats(speed: Double?, distance: Double?, calories: Double?) -> [AnalysisStat] {
        [AnalysisStat(label: "최고속도", value: number(speed, digits: 1), unit: "km/h"),
         AnalysisStat(label: "이동거리", value: number(distance, digits: 2), unit: "km"),
         AnalysisStat(label: "소모칼로리", value: number(calories), unit: "kcal")]
    }
    private static func sections(_ summary: QuarterSummary?) -> [AnalysisSection] {
        guard let summary else { return [] }
        let movement = [
            AnalysisSectionRow(label: "평균 속력", value: number(summary.averageSpeedMps.map { $0 * 3.6 }, digits: 1), unit: "km/h"),
            AnalysisSectionRow(label: "고강도 주행거리", value: number(summary.highIntensityDistanceM), unit: "m"),
            AnalysisSectionRow(label: "방향 전환 횟수", value: number(summary.directionChangeCount.map(Double.init)), unit: "회"),
            AnalysisSectionRow(label: "가속 횟수", value: number(summary.accelerationCount.map(Double.init)), unit: "회"),
            AnalysisSectionRow(label: "감속 횟수", value: number(summary.decelerationCount.map(Double.init)), unit: "회")]
        let heart = [AnalysisSectionRow(label: "최대 심박수", value: number(summary.maxHeartRateBpm), unit: "bpm"),
                     AnalysisSectionRow(label: "평균 심박수", value: number(summary.averageHeartRateBpm), unit: "bpm")]
        var sections = [AnalysisSection(title: "Movement", rows: movement)]
        if summary.maxHeartRateBpm != nil || summary.averageHeartRateBpm != nil {
            sections.append(AnalysisSection(title: "Physical Activity", rows: heart))
        }
        if let trimp = summary.trimpEdwards {
            sections.append(AnalysisSection(title: "Training Load", rows: [AnalysisSectionRow(label: "TRIMP", value: number(trimp), unit: "")]))
        }
        return sections
    }
}

private extension String {
    var leftPaddedToTwoDigits: String { count < 2 ? "0" + self : self }
}
