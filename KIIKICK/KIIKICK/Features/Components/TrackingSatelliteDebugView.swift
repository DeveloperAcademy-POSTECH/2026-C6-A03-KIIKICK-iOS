#if DEBUG
import SwiftUI
import MapKit

/// Debug 전용: 원본 GPS와 정규화 축을 비교하는 위성사진 페이지.
struct TrackingSatelliteDebugView: View {
    let field: Field?
    let points: [TrackPoint]

    @State private var image: UIImage?
    @State private var projectedPoints: [CGPoint] = []
    @State private var projectedCorners: [CGPoint] = []
    @State private var snapshotter: MKMapSnapshotter?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 4) {
            Text("원본 GPS 점 · 가로축(민트) · 세로축(주황)")
                .font(.caption1M)
                .foregroundStyle(.colorTextSecondary)
            GeometryReader { geometry in
                ZStack {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        Canvas { context, _ in
                            var route = Path()
                            for (index, point) in projectedPoints.enumerated() {
                                if index == 0 { route.move(to: point) } else { route.addLine(to: point) }
                            }
                            context.stroke(route, with: .color(.blue500.opacity(0.6)), lineWidth: 1)
                            if projectedCorners.count == 4 {
                                var border = Path()
                                border.addLines(projectedCorners)
                                border.closeSubpath()
                                context.stroke(border, with: .color(.white), lineWidth: 2)
                                var horizontal = Path()
                                horizontal.addLines([projectedCorners[0], projectedCorners[1]])
                                context.stroke(horizontal, with: .color(.mint500), lineWidth: 4)
                                var vertical = Path()
                                vertical.addLines([projectedCorners[0], projectedCorners[3]])
                                context.stroke(vertical, with: .color(.orange500), lineWidth: 4)
                            }
                            var dots = Path()
                            for point in projectedPoints {
                                dots.addEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
                            }
                            context.fill(dots, with: .color(.lime500))
                        }
                        .allowsHitTesting(false)
                    } else if let errorMessage {
                        Text(errorMessage).font(.caption1M).foregroundStyle(.colorTextSecondary)
                    } else {
                        ProgressView().tint(.mint500)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .task(id: geometry.size) { await loadSnapshot(size: geometry.size) }
            }
            Text("GPS \(projectedPoints.count)개 · 방향 전환 전 원본 위치")
                .font(.caption1M)
                .foregroundStyle(.colorTextSecondary)
        }
        .background(Color.gray950)
        .onDisappear { snapshotter?.cancel() }
    }

    @MainActor
    private func loadSnapshot(size: CGSize) async {
        guard size.width > 1, size.height > 1 else { return }
        snapshotter?.cancel()
        image = nil
        errorMessage = nil
        let coordinates = points.compactMap { point -> CLLocationCoordinate2D? in
            let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
            return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
        }
        let corners = field.map { FieldCoordinateMapper(field: $0).orderedCorners } ?? []
        // 운동장이 선택돼 있으면 그 경계에 맞춘다. 멀리 떨어진 GPS 이상치가 축척을 망치지 않게 한다.
        let bounds = corners.isEmpty ? coordinates : corners
        guard let first = bounds.first else {
            errorMessage = "표시할 좌표가 없어요"
            return
        }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for coordinate in bounds {
            minLat = min(minLat, coordinate.latitude); maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude); maxLon = max(maxLon, coordinate.longitude)
        }
        let options = MKMapSnapshotter.Options()
        options.size = size
        options.mapType = .satellite
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.4, 0.0005),
                                   longitudeDelta: max((maxLon - minLon) * 1.4, 0.0005)))
        let request = MKMapSnapshotter(options: options)
        snapshotter = request
        do {
            let snapshot = try await request.start()
            guard !Task.isCancelled else { return }
            projectedPoints = coordinates.map { snapshot.point(for: $0) }.filter {
                $0.x.isFinite && $0.y.isFinite && CGRect(origin: .zero, size: size).contains($0)
            }
            projectedCorners = corners.map { snapshot.point(for: $0) }
            image = snapshot.image
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "위성사진을 불러오지 못했어요"
        }
    }
}
#endif
