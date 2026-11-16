import SwiftUI

struct MockHeatmapRootView: View {
    @State private var store = MockHeatmapStore()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("목업 히트맵 검증", systemImage: "flame.fill")
                            .font(.headline)
                            .foregroundStyle(.mint500)
                        Text("현재 계정의 \(store.position.displayName) 데이터만 생성합니다. 카드를 눌러 쿼터별 타임라인을 확인하세요.")
                            .font(.subheadline)
                            .foregroundStyle(.colorTextSecondary)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.gray850)
                }

                Section("계정 포지션 목업 경기") {
                    ForEach(store.match.players) { player in
                        NavigationLink(value: player.id) {
                            MockHeatmapRowView(player: player)
                        }
                        .listRowBackground(Color.gray850)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.gray950)
            .navigationTitle("목업 히트맵")
            .navigationDestination(for: String.self) { playerID in
                if let player = store.match.players.first(where: { $0.id == playerID }) {
                    MockHeatmapDetailView(player: player)
                } else {
                    ContentUnavailableView("목업 데이터를 찾을 수 없어요", systemImage: "questionmark.folder")
                }
            }
            .navigationDestination(for: MockHeatmapTimelineRoute.self) { route in
                if let player = store.match.players.first(where: { $0.id == route.playerID }),
                   let quarter = player.quarters.first(where: { $0.number == route.quarterNumber }) {
                    TimelineView(
                        dateTitle: "목업 경기",
                        quarter: MockHeatmapAnalysisAdapter.quarter(quarter),
                        focusOnSprint: true
                    )
                } else {
                    ContentUnavailableView("타임라인 데이터를 찾을 수 없어요", systemImage: "clock.badge.questionmark")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("저장", systemImage: "square.and.arrow.down", action: store.save)
                    Button("다시 만들기", systemImage: "arrow.clockwise", action: store.regenerate)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let statusMessage = store.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.colorTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .tint(.mint500)
        .onAppear { store.syncPosition() }
    }
}

#Preview {
    MockHeatmapRootView()
}
