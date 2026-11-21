import SwiftUI

/// 포지션 앵커 박스를 히트맵 위에 겹쳐 확인하는 임시 검증 뷰.
/// 앱의 일반 플로우에는 연결하지 않고, 아래 `#Preview`에서만 사용한다.
struct MockHeatmapAnchorPreviewView: View {
    private struct Item: Identifiable {
        let selectedPosition: MockHeatmapPosition
        let quarterNumber: Int
        let points: [MockHeatmapPoint]

        var id: String { "\(selectedPosition.rawValue)-q\(quarterNumber)" }

        var heatmapPosition: Position {
            selectedPosition.heatmapPosition(for: quarterNumber)
        }
    }

    private let items: [Item]

    init(seed: Int = 102) {
        let match = MockHeatmapGenerator.makeAll(seed: seed)
        items = MockHeatmapPosition.allCases.flatMap { selectedPosition in
            let player = match.players.first { $0.id == selectedPosition.rawValue }
            var positionItems: [Item] = []
            for quarterNumber in 1...MockHeatmapGenerator.quarterCount(seed: seed) {
                guard let quarter = player?.quarters.first(where: { $0.number == quarterNumber }) else { continue }
                positionItems.append(Item(
                    selectedPosition: selectedPosition,
                    quarterNumber: quarterNumber,
                    points: quarter.points
                ))
            }
            return positionItems
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("포지션 앵커 박스 검증")
                    .font(.head2SB)
                    .foregroundStyle(.colorTextPrimary)
                Text("선택 포지션은 유지하고, 생성된 히트맵이 어느 포지션 박스에 치우치는지 확인합니다.")
                    .font(.body4R)
                    .foregroundStyle(.colorTextSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Q\(item.quarterNumber) · 선택 \(item.selectedPosition.workoutPosition.uppercased)")
                                .font(.label1M)
                                .foregroundStyle(.colorTextPrimary)
                            Text("히트맵 박스 \(item.heatmapPosition.uppercased)")
                                .font(.caption1M)
                                .foregroundStyle(item.quarterNumber == 3 ? .orange500 : .mint500)
                            MockHeatmapAnchorCard(
                                points: item.points,
                                position: item.heatmapPosition
                            )
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(10)
                        .background(Color.gray850, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(16)
        }
        .background(Color.gray950)
        .navigationTitle("앵커 박스 미리보기")
    }
}

private struct MockHeatmapAnchorCard: View {
    let points: [MockHeatmapPoint]
    let position: Position

    var body: some View {
        FieldCanvasView { context, size in
            GridDensityHeatmapRenderer().render(
                in: context,
                size: size,
                normalizedPoints: points.map(\.normalizedPoint)
            )

            guard let normalizedRect = MockHeatmapGenerator.anchorRect(for: position) else { return }
            let rect = CGRect(
                x: normalizedRect.minX * size.width,
                y: normalizedRect.minY * size.height,
                width: normalizedRect.width * size.width,
                height: normalizedRect.height * size.height
            )
            context.fill(Path(rect), with: .color(Color.orange500.opacity(0.18)))
            context.stroke(Path(rect), with: .color(.orange500), lineWidth: 2)
        }
        .accessibilityLabel("\(position.uppercased) 포지션 앵커 박스")
    }
}

#Preview("포지션별 앵커 박스") {
    NavigationStack {
        MockHeatmapAnchorPreviewView()
    }
}
