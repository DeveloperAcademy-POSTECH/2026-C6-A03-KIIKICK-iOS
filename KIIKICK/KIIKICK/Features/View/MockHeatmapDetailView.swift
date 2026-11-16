import SwiftUI

struct MockHeatmapDetailView: View {
    let player: MockHeatmapPlayer

    @State private var selectedQuarterNumber = 1

    private var selectedQuarter: MockHeatmapQuarter {
        player.quarters.first(where: { $0.number == selectedQuarterNumber }) ?? player.quarters[0]
    }

    var body: some View {
        let analysisQuarter = MockHeatmapAnalysisAdapter.quarter(selectedQuarter)

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
                    points: analysisQuarter.points,
                    sprintPoints: analysisQuarter.points,
                    isAttackDirectionReversed: analysisQuarter.isAttackDirectionReversed,
                    events: analysisQuarter.events
                )
                .frame(height: 264)
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
