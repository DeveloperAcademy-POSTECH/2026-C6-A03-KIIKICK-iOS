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

        // NMFMapView는 GPU 렌더러라 실제 UIWindow에 붙어 있어야 화면 갱신 루프가 돌고
        // NMFMapViewRenderDelegate 콜백이 호출된다. 윈도우 밖에 띄워두기만 하면(옛
        // MKMapSnapshotter는 윈도우 없이도 동작했지만) 영영 콜백이 오지 않아 무한
        // 로딩으로 보인다 — 그래서 화면 밖(음수 좌표)에 숨긴 전용 윈도우에 붙여둔다.
        let host = OffscreenWindowHost(size: size)
        host.attach(mapView)
        defer { host.detach() }

        let boundsLatLngs = cameraBounds.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        let bounds = NMGLatLngBounds(latLngs: boundsLatLngs)
        let padding = max(size.width, size.height) * 0.18
        await mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: padding))

        guard let image = await waitForRenderedImage(mapView: mapView, size: size) else { return nil }

        let points = coordinates.map { mapView.projection.point(from: NMGLatLng(lat: $0.latitude, lng: $0.longitude)) }
        return (image, points)
    }

    /// 렌더 완료 콜백을 기다리되, 인증 실패 등으로 콜백이 영영 안 올 수도 있으므로
    /// 타임아웃을 둬서 무한 로딩 대신 nil(= 기존 placeholder)로 빠지게 한다.
    @MainActor
    private static func waitForRenderedImage(mapView: NMFMapView, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            var didResume = false
            let resumeOnce: (UIImage?) -> Void = { image in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: image)
            }

            let observer = RenderCompletionObserver(mapView: mapView) {
                let image = UIGraphicsImageRenderer(size: size).image { _ in
                    mapView.drawHierarchy(in: mapView.bounds, afterScreenUpdates: true)
                }
                resumeOnce(image)
            }
            observer.start()

            Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                observer.cancel()
                resumeOnce(nil)
            }
        }
    }
}

/// 화면 밖(음수 좌표)에 둔 전용 윈도우. GPU 기반 뷰가 렌더 루프를 돌리려면 실제
/// 윈도우 계층에 붙어 있어야 해서, 보이지 않게 치워둔 채로 그 역할만 한다.
@MainActor
private final class OffscreenWindowHost {
    private let window: UIWindow?

    init(size: CGSize) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first

        guard let scene else {
            window = nil
            return
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: -10_000, y: -10_000, width: size.width, height: size.height)
        window.windowLevel = .normal - 1000
        window.isUserInteractionEnabled = false
        window.isHidden = false
        self.window = window
    }

    func attach(_ view: UIView) {
        window?.addSubview(view)
    }

    func detach() {
        window?.subviews.forEach { $0.removeFromSuperview() }
        window?.isHidden = true
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

    func cancel() {
        guard !hasFired else { return }
        hasFired = true
        mapView.removeRenderDelegate(delegate: self)
    }

    func mapViewDidFinishRenderingFrame(_ mapView: NMFMapView, fully: Bool, stable: Bool) {
        guard fully, stable, !hasFired else { return }
        hasFired = true
        mapView.removeRenderDelegate(delegate: self)
        onReady()
    }
}
