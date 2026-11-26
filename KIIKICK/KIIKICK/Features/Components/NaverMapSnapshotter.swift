//
//  NaverMapSnapshotter.swift
//  KIIKICK
//
//  MKMapSnapshotter를 대체한다. NMFMapView엔 오프스크린 스냅샷 API가 없어서,
//  화면 밖에 NMFMapView를 띄우고 NMFMapViewRenderDelegate로 타일 로딩 완료를
//  감지한 뒤 뷰 자체를 비트맵으로 캡처한다.
//

import CoreLocation
import NMapsGeometry
import NMapsMap
import UIKit

enum NaverMapSnapshotter {

    @MainActor
    static func renderSnapshot(for coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        guard let result = await renderSnapshotWithProjection(
            cameraBounds: coordinates,
            projecting: coordinates,
            size: size
        ) else { return nil }

        guard coordinates.count == 4 else { return result.image }

        return UIGraphicsImageRenderer(size: size).image { _ in
            result.image.draw(at: .zero)

            let points = result.points
            guard let first = points.first else { return }
            let path = UIBezierPath()
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.close()

            UIColor.white.withAlphaComponent(0.2).setFill()
            path.fill()
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    /// `cameraBounds`로 카메라를 맞추고, `projecting`에 있는 모든 좌표의 화면 투영점을
    /// 같은 순서로 돌려준다 (오프스크린 렌더를 1회만 수행하기 위해 분리했다).
    @MainActor
    static func renderSnapshotWithProjection(
        cameraBounds: [CLLocationCoordinate2D],
        projecting coordinates: [CLLocationCoordinate2D],
        size: CGSize
    ) async -> (image: UIImage, points: [CGPoint])? {
        guard !cameraBounds.isEmpty, size.width > 0, size.height > 0 else { return nil }

        let mapView = NMFMapView(frame: CGRect(origin: .zero, size: size))
        mapView.mapType = .satellite
        mapView.isNightModeEnabled = false

        let boundsLatLngs = cameraBounds.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        let bounds = NMGLatLngBounds(latLngs: boundsLatLngs)
        let padding = max(size.width, size.height) * 0.18
        await mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: padding))

        guard let image = await waitForRenderedImage(mapView: mapView, size: size) else { return nil }

        let points = coordinates.map { mapView.projection.point(from: NMGLatLng(lat: $0.latitude, lng: $0.longitude)) }
        return (image, points)
    }

    @MainActor
    private static func waitForRenderedImage(mapView: NMFMapView, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let observer = RenderCompletionObserver(mapView: mapView) {
                let image = UIGraphicsImageRenderer(size: size).image { _ in
                    mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
                }
                continuation.resume(returning: image)
            }
            observer.start()
        }
    }
}

/// NMFMapViewRenderDelegate는 프레임마다 호출되므로, fully && stable이 되는
/// 첫 프레임에서 한 번만 콜백을 실행하고 스스로 떼어낸다. mapView를 강하게 붙잡고 있어야
/// 캡처가 끝나기 전에 화면 밖 지도 인스턴스가 해제되지 않는다.
private final class RenderCompletionObserver: NSObject, NMFMapViewRenderDelegate {
    private let mapView: NMFMapView
    private let onReady: () -> Void
    private var hasFired = false

    init(mapView: NMFMapView, onReady: @escaping () -> Void) {
        self.mapView = mapView
        self.onReady = onReady
    }

    func start() {
        mapView.addRenderDelegate(delegate: self)
    }

    func mapViewDidFinishRenderingFrame(_ mapView: NMFMapView, fully: Bool, stable: Bool) {
        guard fully, stable, !hasFired else { return }
        hasFired = true
        mapView.removeRenderDelegate(delegate: self)
        onReady()
    }
}
