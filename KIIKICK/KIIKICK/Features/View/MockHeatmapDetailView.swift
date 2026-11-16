import SwiftUI

struct MockHeatmapDetailView: View {
    let player: MockHeatmapPlayer

    @State private var selectedQuarterNumber = 1
    @State private var playbackTime: TimeInterval = TimelineWindow.length
    @State private var isSprintPageSelected = false

    private var selectedQuarter: MockHeatmapQuarter {
        player.quarters.first(where: { $0.number == selectedQuarterNumber }) ?? player.quarters[0]
    }

    private var analysisQuarter: AnalysisQuarter {
        MockHeatmapAnalysisAdapter.quarter(selectedQuarter)
    }

    private var sprintSegments: [Sprint] {
        SprintDetector().detect(in: analysisQuarter.points)
    }

    private var sprintEndElapsedTimes: [TimeInterval] {
        guard let startDate = analysisQuarter.startDate else { return [] }
        return sprintSegments.compactMap { sprint in
            let elapsed = sprint.end.timestamp.timeIntervalSince(startDate)
            guard elapsed >= 0, elapsed <= analysisQuarter.duration else { return nil }
            return elapsed
        }
    }

    private var selectedSprint: Sprint? {
        guard isSprintPageSelected, let startDate = analysisQuarter.startDate else { return nil }
        return sprintSegments.min { lhs, rhs in
            let lhsElapsed = lhs.end.timestamp.timeIntervalSince(startDate)
            let rhsElapsed = rhs.end.timestamp.timeIntervalSince(startDate)
            return abs(lhsElapsed - playbackTime) < abs(rhsElapsed - playbackTime)
        }
    }

    private var playbackBinding: Binding<TimeInterval> {
        Binding(
            get: { playbackTime },
            set: { playbackTime = snappedPlaybackTime($0) }
        )
    }

    private var nearestSprintIndex: Int? {
        guard isSprintPageSelected, !sprintEndElapsedTimes.isEmpty else { return nil }
        return sprintEndElapsedTimes.enumerated().min { lhs, rhs in
            abs(lhs.element - playbackTime) < abs(rhs.element - playbackTime)
        }?.offset
    }

    private var sprintSliderBinding: Binding<Double> {
        Binding(
            get: { Double(nearestSprintIndex ?? 0) },
            set: { value in
                let index = Int(value.rounded())
                guard sprintEndElapsedTimes.indices.contains(index) else { return }
                playbackTime = sprintEndElapsedTimes[index]
            }
        )
    }

    private func snappedPlaybackTime(_ value: TimeInterval) -> TimeInterval {
        let clampedValue = min(max(0, value), max(analysisQuarter.duration, 1))
        guard isSprintPageSelected, let nearest = sprintEndElapsedTimes.min(by: {
            abs($0 - clampedValue) < abs($1 - clampedValue)
        }) else {
            return clampedValue
        }
        return nearest
    }

    private var playbackTimeText: String {
        let seconds = max(0, Int(playbackTime))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        let window = analysisQuarter.startDate.map {
            TimelineWindow(quarterStart: $0, duration: analysisQuarter.duration, elapsed: playbackTime)
        }
        let visiblePoints = analysisQuarter.points.filter { window?.contains($0.timestamp) == true }
        let visibleSprintPoints = selectedSprint?.points ?? []
        let visibleEvents = analysisQuarter.events.filter { window?.contains($0.timestamp) == true }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                stats
                Picker("쿼터", selection: $selectedQuarterNumber) {
                    ForEach(player.quarters) { quarter in
                        Text("\(quarter.number)Q").tag(quarter.number)
                    }
                }
                .pickerStyle(.segmented)
                HStack(spacing: 12) {
                    Label("골 \(selectedQuarter.goalCount)", systemImage: "soccerball")
                    Label("어시스트 \(selectedQuarter.assistCount)", systemImage: "arrow.triangle.branch")
                }
                .font(.subheadline)
                .foregroundStyle(.colorTextSecondary)
                Text("좌우로 넘겨 히트맵과 스프린트를 확인하세요")
                    .font(.caption1M)
                    .foregroundStyle(.colorTextSecondary)
                TrackingMapPager(
                    field: analysisQuarter.field,
                    points: visiblePoints,
                    sprintPoints: isSprintPageSelected ? visibleSprintPoints : nil,
                    isAttackDirectionReversed: analysisQuarter.isAttackDirectionReversed,
                    events: visibleEvents,
                    onSprintSelectionChanged: { isSprintSelected in
                        isSprintPageSelected = isSprintSelected
                        if isSprintSelected {
                            playbackTime = snappedPlaybackTime(playbackTime)
                        }
                    }
                )
                .frame(height: 264)
                .id(selectedQuarterNumber)

                VStack(spacing: 4) {
                    Text(playbackTimeText)
                        .font(.title2SB)
                        .foregroundStyle(.colorTextPrimary)
                    Group {
                        if isSprintPageSelected, sprintEndElapsedTimes.count >= 2 {
                            Slider(
                                value: sprintSliderBinding,
                                in: 0...Double(sprintEndElapsedTimes.count - 1),
                                step: 1
                            ) {
                                Text("스프린트 구간")
                            }
                        } else {
                            Slider(value: playbackBinding, in: 0...max(analysisQuarter.duration, 1)) {
                                Text("재생 위치")
                            }
                        }
                    }
                    .tint(.mint500)
                    .disabled(analysisQuarter.startDate == nil || analysisQuarter.duration <= 0)
                    .accessibilityValue("\(playbackTimeText), 전체 \(analysisQuarter.durationText)")
                    .accessibilityHint(isSprintPageSelected ? "스프린트 종료 구간 단위로 이동" : "최근 20초 구간 표시")
                    if isSprintPageSelected, !sprintSegments.isEmpty {
                        Text("스프린트 종료 구간 단위로 이동")
                            .font(.caption1M)
                            .foregroundStyle(.colorTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(analysisQuarter.durationText)
                        .font(.caption1M)
                        .foregroundStyle(.colorTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                NavigationLink(value: MockHeatmapTimelineRoute(playerID: player.id, quarterNumber: selectedQuarter.number)) {
                    Label("기존 타임라인 보기", systemImage: "timeline.selection")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint500)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.gray950)
        .navigationTitle("히트맵 상세")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedQuarterNumber) { _, _ in
            playbackTime = min(TimelineWindow.length, max(0, analysisQuarter.duration))
            isSprintPageSelected = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(player.displayName)
                .font(.title2.bold())
                .foregroundStyle(.colorTextPrimary)
            Text("\(player.role) · 실제 선수 데이터가 아닌 스타일 기반 목업")
                .font(.subheadline)
                .foregroundStyle(.colorTextSecondary)
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            MockHeatmapStat(title: "평균 속도", value: player.averageSpeedKmh, unit: "km/h")
            MockHeatmapStat(title: "최고 속도", value: player.maxSpeedKmh, unit: "km/h")
            MockHeatmapStat(title: "평균 심박", value: player.averageHeartRate, unit: "bpm")
        }
    }
}
