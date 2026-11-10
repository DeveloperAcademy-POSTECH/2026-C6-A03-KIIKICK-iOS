//
//  AnalysisEntry+WorkoutRecord.swift
//  KIIKICK
//
//  이슈 #43: AnalysisMockData를 치우고 실제 WorkoutRecord에서 AnalysisEntry를 만든다.
//  쿼터 하나 = WorkoutRecord 하나(WorkoutManager.beginQuarter/endQuarter, 쿼터 하나 =
//  WorkoutPayload 하나 참고) — 같은 날 같은 운동장에서 기록된 WorkoutRecord들을 모으면
//  그게 "경기(AnalysisEntry)"다. 그룹핑(같은 날·같은 운동장으로 묶기)은 호출부(AnalysisView)가
//  한다 — 이 파일은 "이미 한 경기로 묶인 WorkoutRecord 묶음"을 받아서 값을 채우기만 한다.
//
//  Training Load(TRIMP, Player Load) 섹션은 넣지 않는다 — 안정시/최대 심박수, 체중 같은
//  입력값이 없어서 계산할 근거가 없다. 실제 공식 없이 숫자를 만들어내는 것보다, 계산할
//  수 없는 섹션은 아예 보여주지 않는 쪽을 택했다.
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

extension AnalysisEntry {
    /// 분석 목록과 알림에서 같은 경기/쿼터 묶음을 사용한다.
    static func grouped(from records: [WorkoutRecord]) -> [AnalysisEntry] {
        let sorted = records.sorted { $0.date < $1.date }
        var groups: [[WorkoutRecord]] = []
        for record in sorted {
            if let last = groups.last?.last,
               last.field?.persistentModelID == record.field?.persistentModelID,
               record.date.timeIntervalSince(last.date.addingTimeInterval(last.duration)) <= 10 * 60 {
                groups[groups.count - 1].append(record)
            } else {
                groups.append([record])
            }
        }
        return groups.compactMap { Self.build(from: $0) }.sorted { $0.date > $1.date }
    }

    static func build(from records: [WorkoutRecord]) -> AnalysisEntry? {
        let sortedRecords = records.sorted { $0.date < $1.date }
        guard let first = sortedRecords.first else { return nil }

        // 이슈 #66: 같은 경기로 묶인 레코드들이 workout-submissions에 같은 matchId를
        // 쓰도록 맞춘다 — 각 레코드는 만들어질 때 각자 다른 matchId를 받았을 수 있다.
        for record in sortedRecords where record.matchId != first.matchId {
            record.matchId = first.matchId
        }

        let allPoints = sortedRecords.flatMap(\.points)
        let allEvents = sortedRecords.flatMap(\.events)
        let allHeartRate = sortedRecords.flatMap(\.heartRateSamples)

        let maxSpeedKmh = (allPoints.map(\.speed).max() ?? 0) * 3.6
        let totalDistanceKm = sortedRecords.reduce(0.0) { $0 + $1.totalDistance } / 1000
        let totalCalories = sortedRecords.reduce(0.0) { $0 + $1.totalCalories }
        let goalCount = allEvents.filter { $0.type == .goal }.count
        let assistCount = allEvents.filter { $0.type == .assist }.count

        let stats = [
            AnalysisStat(label: "최고속도", value: String(format: "%.1f", maxSpeedKmh), unit: "km/h"),
            AnalysisStat(label: "이동거리", value: String(format: "%.2f", totalDistanceKm), unit: "km"),
            AnalysisStat(label: "소모칼로리", value: String(format: "%.0f", totalCalories), unit: "kcal"),
        ]

        let quarters = sortedRecords.enumerated().map { index, record in
            var quarter = AnalysisQuarter(
                quarterNumber: index + 1,
                durationText: formattedDuration(record.duration),
                startDate: record.date,
                duration: record.duration,
                position: record.position?.uppercased,
                field: record.field,
                points: record.points,
                events: record.events.map { event in
                    AnalysisMatchEvent(
                        type: event.type == .goal ? .goal : .assist,
                        timeText: formattedDuration(event.location.timestamp.timeIntervalSince(record.date)),
                        timestamp: event.location.timestamp,
                        position: normalizedPosition(of: event.location, in: record.field)
                    )
                },
                totalDistanceKm: record.totalDistance / 1000,
                totalCaloriesKcal: record.totalCalories
            )
            quarter.isAttackDirectionReversed = record.isAttackDirectionReversed
            quarter.sourceRecord = record
            return quarter
        }

        var sections: [AnalysisSection] = [movementSection(points: allPoints)]
        if !allHeartRate.isEmpty {
            sections.append(physicalActivitySection(samples: allHeartRate))
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일"
        let dateTitle = dateFormatter.string(from: first.date)

        return AnalysisEntry(
            date: first.date,
            dateAndQuarter: "\(dateTitle) • 총 \(sortedRecords.count)Q",
            fieldName: first.field?.name ?? "운동장 미지정",
            stats: stats,
            detail: AnalysisDetail(
                title: dateTitle,
                quarters: quarters,
                keyStats: stats,
                goalCount: goalCount,
                assistCount: assistCount,
                sections: sections,
                disclaimer: "히트맵과 포지션이 정확한지 확인해주세요"
            ),
            records: sortedRecords
        )
    }

    private static func normalizedPosition(of point: TrackPoint, in field: Field?) -> UnitPoint {
        guard let field else { return UnitPoint(x: 0.5, y: 0.5) }
        let normalized = FieldCoordinateMapper(field: field).normalize(
            CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        )
        return UnitPoint(x: normalized.x, y: normalized.y)
    }

    private static func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    /// DESIGN-GAP: 고강도 주행거리/방향 전환/가속·감속 횟수는 검증된 스포츠과학 공식이
    /// 아니라 TrackPoint의 speed/course로 계산한 근사치다. 임계값(고강도 5.5m/s≈19.8km/h,
    /// 방향전환 45˚, 가속/감속 0.5m/s²)은 흔히 쓰이는 값을 참고했을 뿐이라 추후 조정될 수 있다.
    private static func movementSection(points: [TrackPoint]) -> AnalysisSection {
        let sorted = points.sorted { $0.timestamp < $1.timestamp }
        let avgSpeedKmh = sorted.isEmpty ? 0 : (sorted.map(\.speed).reduce(0, +) / Double(sorted.count)) * 3.6

        var highIntensityDistance: Double = 0
        var directionChanges = 0
        var accelerations = 0
        var decelerations = 0

        for (prev, curr) in zip(sorted, sorted.dropFirst()) {
            let prevLocation = CLLocation(latitude: prev.latitude, longitude: prev.longitude)
            let currLocation = CLLocation(latitude: curr.latitude, longitude: curr.longitude)
            let distance = currLocation.distance(from: prevLocation)

            if curr.speed > 5.5 { highIntensityDistance += distance }

            let courseDelta = abs(curr.course - prev.course)
            if min(courseDelta, 360 - courseDelta) > 45 { directionChanges += 1 }

            let speedDelta = curr.speed - prev.speed
            if speedDelta > 0.5 { accelerations += 1 }
            if speedDelta < -0.5 { decelerations += 1 }
        }

        return AnalysisSection(title: "Movement", rows: [
            AnalysisSectionRow(label: "평균 속력", value: String(format: "%.1f", avgSpeedKmh), unit: "km/h"),
            AnalysisSectionRow(label: "고강도 주행거리", value: String(format: "%.0f", highIntensityDistance), unit: "m"),
            AnalysisSectionRow(label: "방향 전환 횟수", value: "\(directionChanges)", unit: "회"),
            AnalysisSectionRow(label: "가속 횟수", value: "\(accelerations)", unit: "회"),
            AnalysisSectionRow(label: "감속 횟수", value: "\(decelerations)", unit: "회"),
        ])
    }

    private static func physicalActivitySection(samples: [HeartRateSample]) -> AnalysisSection {
        let maxBpm = samples.map(\.bpm).max() ?? 0
        let avgBpm = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
        return AnalysisSection(title: "Physical Activity", rows: [
            AnalysisSectionRow(label: "최대 심박수", value: String(format: "%.0f", maxBpm), unit: "bpm"),
            AnalysisSectionRow(label: "평균 심박수", value: String(format: "%.0f", avgBpm), unit: "bpm"),
        ])
    }
}
