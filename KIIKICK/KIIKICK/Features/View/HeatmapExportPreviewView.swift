import SwiftUI
import Photos
import CoreLocation

/// GK를 제외한 9개 포지션의 목업 히트맵을 그리드로 미리 보고, 고해상도 PNG로
/// 사진앱에 저장해 확대 품질을 확인하는 임시 검증 뷰.
/// 상세 화면에서는 `TrackingMapPager`로 히트맵과 스프린트를 좌우로 넘겨 함께 확인할 수 있고,
/// 저장 버튼은 그 중 현재 보고 있는 페이지를 그대로 내보낸다.
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
    @State private var isSprintSelected = false

    private enum SaveState: Equatable {
        case idle, saving, success, failure(String)
    }

    private var trackPoints: [TrackPoint] {
        points.map(MockHeatmapAnalysisAdapter.trackPoint)
    }

    var body: some View {
        VStack(spacing: 24) {
            TrackingMapPager(
                field: MockHeatmapAnalysisAdapter.field(),
                points: trackPoints,
                onSprintSelectionChanged: { isSprintSelected = $0 }
            )
            .frame(height: 264)
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

    // SprintMapView를 그대로 쓰지 않는 이유: 그 화살표 두께/길이는 화면 표시 폭(약 345pt)
    // 기준 고정값이라, artwork 해상도(1536pt)로 내보내면 필드 대비 화살표가 가늘고
    // 작아 보인다. 저장 전용으로 같은 로직을 재구성하되 캔버스 폭에 비례해 굵게 그린다.
    private var sprintCard: some View {
        let mapper = FieldCoordinateMapper(field: MockHeatmapAnalysisAdapter.field())
        let visibleSprints = SprintDetector().detect(in: trackPoints).compactMap { sprint -> (start: CGPoint, end: CGPoint, isAttackDirection: Bool)? in
            let positions = sprint.points.compactMap { point -> CGPoint? in
                let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
                let normalized = mapper.normalize(coordinate)
                guard normalized.x.isFinite, normalized.y.isFinite,
                      (0...1).contains(normalized.x), (0...1).contains(normalized.y) else { return nil }
                return normalized
            }
            guard let start = positions.first, let end = positions.last, start != end else { return nil }
            return (start, end, end.x - start.x > 0)
        }

        return FieldCanvasView { context, size in
            // SprintMapView가 345pt 표시 폭 기준으로 lineWidth 3 / 화살표 길이 8을 쓰므로,
            // 실제 캔버스 폭에 비례해 그만큼 키운다.
            let scale = size.width / 345
            for sprint in visibleSprints {
                Self.drawExportArrow(
                    from: CGPoint(x: sprint.start.x * size.width, y: sprint.start.y * size.height),
                    to: CGPoint(x: sprint.end.x * size.width, y: sprint.end.y * size.height),
                    isAttackDirection: sprint.isAttackDirection,
                    scale: scale,
                    in: context, size: size
                )
            }
        }
    }

    private static func drawExportArrow(
        from start: CGPoint,
        to end: CGPoint,
        isAttackDirection: Bool,
        scale: CGFloat,
        in context: GraphicsContext,
        size: CGSize
    ) {
        guard let curve = SprintArrowGeometry(start: start, end: end) else { return }
        let control = CGPoint(x: min(max(curve.control.x, 0), size.width),
                              y: min(max(curve.control.y, 0), size.height))
        var line = Path()
        line.move(to: start)
        line.addQuadCurve(to: end, control: control)
        let arrowColor: Color = isAttackDirection ? .lime500 : .orange500
        context.stroke(line, with: .color(arrowColor), style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round))

        let angle = atan2(end.y - control.y, end.x - control.x)
        let arrowLength = 8 * scale
        let arrowAngle: CGFloat = .pi / 7

        let left = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let right = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        var head = Path()
        head.move(to: left)
        head.addLine(to: end)
        head.addLine(to: right)
        head.closeSubpath()
        context.fill(head, with: .color(arrowColor))
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
        // 현재 TrackingMapPager에서 보고 있는 페이지(히트맵/스프린트)를 그대로 내보낸다.
        let card = isSprintSelected ? AnyView(sprintCard) : AnyView(heatmapCard)
        let exportCard = card
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
