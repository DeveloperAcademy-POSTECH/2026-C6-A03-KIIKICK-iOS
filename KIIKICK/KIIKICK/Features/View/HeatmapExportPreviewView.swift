import SwiftUI
import Photos

/// GK를 제외한 9개 포지션의 목업 히트맵을 그리드로 미리 보고, 고해상도 PNG로
/// 사진앱에 저장해 확대 품질을 확인하는 임시 검증 뷰.
/// 앱의 일반 플로우에는 연결하지 않고, RootView의 `#if DEBUG` 블록에서만 띄운다.
struct HeatmapExportPreviewView: View {
    private struct Item: Identifiable {
        let position: Position
        let points: [MockHeatmapPoint]
        var id: String { position.rawValue }
    }

    private let items: [Item]

    init(seed: Int = 102) {
        items = Position.allCases
            .filter { $0 != .gk }
            .map { position in
                Item(
                    position: position,
                    points: MockHeatmapGenerator.makeSamplePoints(seed: seed, position: position)
                )
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            HeatmapExportDetailView(position: item.position, points: item.points)
                        } label: {
                            HeatmapExportThumbnail(position: item.position, points: item.points)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color.gray950)
            .navigationTitle("히트맵 내보내기 검증")
        }
    }
}

private struct HeatmapExportThumbnail: View {
    let position: Position
    let points: [MockHeatmapPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(position.uppercased)
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            FieldCanvasView { context, size in
                GridDensityHeatmapRenderer().render(
                    in: context,
                    size: size,
                    normalizedPoints: points.map(\.normalizedPoint)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(10)
        .background(Color.gray850, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct HeatmapExportDetailView: View {
    let position: Position
    let points: [MockHeatmapPoint]

    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle, saving, success, failure(String)
    }

    var body: some View {
        VStack(spacing: 24) {
            heatmapCard
                .padding(.horizontal, 16)

            Text(statusText)
                .font(.title2SB)
                .foregroundStyle(.colorTextPrimary)

            Button(action: save) {
                Image("ic_download")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.colorTextPrimary)
                    .padding(16)
                    .background(Color.gray800, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(saveState == .saving)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle(position.uppercased)
    }

    private var heatmapCard: some View {
        FieldCanvasView { context, size in
            GridDensityHeatmapRenderer().render(
                in: context,
                size: size,
                normalizedPoints: points.map(\.normalizedPoint)
            )
        }
    }

    private var statusText: String {
        switch saveState {
        case .idle, .saving: "고해상도 이미지 저장"
        case .success: "사진 앱에 저장됐어요"
        case .failure(let message): message
        }
    }

    @MainActor
    private func save() {
        let exportCard = heatmapCard
            .frame(width: FieldArtworkLayout.artworkSize.width, height: FieldArtworkLayout.artworkSize.height)

        let renderer = ImageRenderer(content: exportCard)
        // 디바이스 스케일(2x/3x) 대신 고정된 높은 값을 써서, 시뮬레이터에서도
        // 항상 확대에 안전한 큰 PNG가 나오게 한다.
        renderer.scale = 8
        renderer.isOpaque = false

        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else {
            saveState = .failure("이미지를 만들지 못했어요")
            return
        }

        saveState = .saving
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveState = .failure("사진 접근 권한이 필요해요")
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: pngData, options: nil)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        saveState = success ? .success : .failure(error?.localizedDescription ?? "저장 실패")
                    }
                }
            }
        }
    }
}

#Preview("히트맵 내보내기 검증") {
    HeatmapExportPreviewView()
}
