//
//  NaverMapView.swift
//  KIIKICK
//
//  FieldCreationView의 "꼭짓점 4개 찍기" 지도를 담당한다. NMFMarker엔 네이티브
//  draggable이 없어서(MapKit의 Annotation도 마찬가지였다) UIPanGestureRecognizer로
//  수동 드래그를 구현한다 — 터치 시작 지점과 각 마커의 화면좌표(projection)를 비교해
//  어떤 마커를 드래그하는지 판정한다.
//

import CoreLocation
import NMapsGeometry
import NMapsMap
import SwiftUI

struct NaverMapView: UIViewRepresentable {
    @Binding var pins: [CLLocationCoordinate2D]
    var draggingIndex: Binding<Int?>
    var onTapEmptyMap: (CLLocationCoordinate2D) -> Void
    var recenterTrigger: Bool

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        mapView.mapType = .satellite
        mapView.touchDelegate = context.coordinator

        let existingPins = pins
        if existingPins.count == 4 {
            // 기존 경기장을 수정하는 경우: 내 위치로 따라가지 않고, 등록된 네 꼭짓점이
            // 다 보이도록 한 번만 카메라를 맞춘다.
            mapView.positionMode = .normal
            let bounds = NMGLatLngBounds(latLngs: existingPins.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
            Task { @MainActor in
                await mapView.moveCamera(NMFCameraUpdate(fit: bounds, padding: 60))
            }
        } else {
            // 새로 등록하는 경우: 사용자 위치로 이동해 따라간다. positionMode만
            // 설정해서는 카메라가 움직이지 않는다 — NMFMapView는 CoreLocation을 직접
            // 구독하지 않고, 별도 싱글턴인 NMFLocationManager가 위치 업데이트를
            // 시작해야 locationOverlay/카메라가 따라온다. positionMode의 "따라가기"는
            // 이후 위치가 갱신될 때부터 작동하고 첫 진입 시 바로 이동시켜주진 않아서,
            // 이미 알고 있는 위치가 있으면 즉시 한 번 옮기고(moveToCurrentLocationIfAvailable),
            // 아직 없으면 첫 위치 업데이트 콜백에서 옮긴다.
            mapView.positionMode = .direction
            NMFLocationManager.sharedInstance().add(context.coordinator)
            NMFLocationManager.sharedInstance().startUpdatingLocation()
            context.coordinator.mapView = mapView
            context.coordinator.moveToCurrentLocationIfAvailable()
        }

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        mapView.addGestureRecognizer(pan)

        // 지도 자체의 내장 팬 제스처가 마커 드래그와 동시에 인식되면 배경 지도까지
        // 같이 움직여버린다. 내 제스처가 마커 근처가 아니면 shouldReceive에서 바로
        // 거절해 즉시 실패하므로, 지도의 팬 제스처가 "내 제스처가 먼저 실패하길"
        // 기다리게 해도(require(toFail:)) 체감 딜레이는 없다.
        mapView.gestureRecognizers?
            .filter { $0 !== pan && $0 is UIPanGestureRecognizer }
            .forEach { $0.require(toFail: pan) }

        context.coordinator.mapView = mapView
        return mapView
    }

    static func dismantleUIView(_ uiView: NMFMapView, coordinator: Coordinator) {
        NMFLocationManager.sharedInstance().stopUpdatingLocation()
        NMFLocationManager.sharedInstance().remove(coordinator)
    }

    func updateUIView(_ mapView: NMFMapView, context: Context) {
        context.coordinator.sync(pins: pins)

        if recenterTrigger != context.coordinator.lastRecenterTrigger {
            context.coordinator.lastRecenterTrigger = recenterTrigger
            Task { @MainActor in
                await mapView.moveCamera(NMFCameraUpdate(scrollTo: mapView.locationOverlay.location))
            }
        }
        // 핀 4개를 다 찍어도 카메라를 자동으로 움직이지 않는다 — fit-bounds 카메라
        // 업데이트가 heading을 북쪽으로 되돌리고 positionMode도 .direction에서
        // .normal로 풀어버려서, 사용자가 보던 각도/내 위치 추종이 끊기는 부작용이
        // 있었다(#105 후속 피드백). 전체 보기가 필요하면 사용자가 직접 핀치줌한다.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pins: $pins, draggingIndex: draggingIndex, onTapEmptyMap: onTapEmptyMap)
    }

    @MainActor
    final class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFLocationManagerDelegate, UIGestureRecognizerDelegate {
        private var pins: Binding<[CLLocationCoordinate2D]>
        private var draggingIndex: Binding<Int?>
        private let onTapEmptyMap: (CLLocationCoordinate2D) -> Void
        weak var mapView: NMFMapView?
        private var markers: [NMFMarker] = []
        private var polyline: NMFPolylineOverlay?
        var lastRecenterTrigger = false
        private var draggingMarkerIndex: Int?
        private var hasMovedToInitialLocation = false

        init(
            pins: Binding<[CLLocationCoordinate2D]>,
            draggingIndex: Binding<Int?>,
            onTapEmptyMap: @escaping (CLLocationCoordinate2D) -> Void
        ) {
            self.pins = pins
            self.draggingIndex = draggingIndex
            self.onTapEmptyMap = onTapEmptyMap
        }

        /// 마커/폴리라인을 pins 배열과 동기화한다. SwiftUI의 선언적 모델을 NMFMapView의
        /// 명령형 오버레이 API로 매번 다시 그리지 않고 diff 없이 전체 재생성한다 —
        /// 핀 개수가 최대 4개뿐이라 성능 영향이 없다. 드래그 중인 마커는 제스처가 이미
        /// 직접 위치를 갱신하고 있으므로 다시 만들지 않는다.
        func sync(pins newPins: [CLLocationCoordinate2D]) {
            guard draggingMarkerIndex == nil else { return }

            markers.forEach { $0.mapView = nil }
            markers = newPins.enumerated().map { index, coordinate in
                let marker = NMFMarker(position: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude))
                marker.iconImage = NMFOverlayImage(image: Self.pinImage(number: index + 1))
                marker.anchor = CGPoint(x: 0.5, y: 0.5)
                marker.mapView = mapView
                return marker
            }

            rebuildPolyline(from: newPins)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let mapView else { return }
            let location = gesture.location(in: mapView)

            switch gesture.state {
            case .began:
                draggingMarkerIndex = nearestMarkerIndex(to: location, within: 28)
                if let draggingMarkerIndex {
                    draggingIndex.wrappedValue = draggingMarkerIndex
                }
            case .changed:
                guard let index = draggingMarkerIndex, markers.indices.contains(index) else { return }
                let latLng = mapView.projection.latlng(from: location)
                markers[index].position = latLng
                var updated = pins.wrappedValue
                updated[index] = CLLocationCoordinate2D(latitude: latLng.lat, longitude: latLng.lng)
                pins.wrappedValue = updated
                rebuildPolyline(from: updated)
            case .ended, .cancelled, .failed:
                draggingMarkerIndex = nil
                draggingIndex.wrappedValue = nil
            default:
                break
            }
        }

        private func nearestMarkerIndex(to location: CGPoint, within maxDistance: CGFloat) -> Int? {
            guard let mapView else { return nil }
            var bestIndex: Int?
            var bestDistance = CGFloat.greatestFiniteMagnitude
            for (index, marker) in markers.enumerated() {
                let point = mapView.projection.point(from: marker.position)
                let distance = hypot(point.x - location.x, point.y - location.y)
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndex = index
                }
            }
            return bestDistance < maxDistance ? bestIndex : nil
        }

        private func rebuildPolyline(from coordinates: [CLLocationCoordinate2D]) {
            polyline?.mapView = nil
            guard coordinates.count >= 2 else { polyline = nil; return }
            let closed = coordinates.count == 4 ? coordinates + [coordinates[0]] : coordinates
            let overlay = NMFPolylineOverlay(closed.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
            overlay?.color = UIColor(Color.mint500).withAlphaComponent(0.8)
            overlay?.width = 2
            overlay?.pattern = [6, 5]
            overlay?.mapView = mapView
            polyline = overlay
        }

        private static func pinImage(number: Int) -> UIImage {
            let size = CGSize(width: 44, height: 44)
            return UIGraphicsImageRenderer(size: size).image { _ in
                let rect = CGRect(x: 8, y: 8, width: 28, height: 28)
                UIColor(Color.gray950).setFill()
                UIBezierPath(ovalIn: rect).fill()
                UIColor(Color.mint500).setStroke()
                let stroke = UIBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5))
                stroke.lineWidth = 3
                stroke.stroke()
                let text = "\(number)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor(Color.mint500),
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                ]
                let textSize = text.size(withAttributes: attrs)
                text.draw(
                    at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2),
                    withAttributes: attrs
                )
            }
        }

        // MARK: - NMFMapViewTouchDelegate

        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            guard draggingMarkerIndex == nil else { return }
            onTapEmptyMap(CLLocationCoordinate2D(latitude: latlng.lat, longitude: latlng.lng))
        }

        // MARK: - NMFLocationManagerDelegate

        /// positionMode = .direction는 "위치가 갱신될 때부터" 카메라를 따라가게 할 뿐,
        /// 아직 한 번도 위치가 없던 상태에서 처음 진입했을 땐 그 전까지 카메라가 가만히
        /// 있는다 — 그래서 위치를 쓸 수 있게 되는 첫 순간(이미 알고 있었으면 즉시,
        /// 아니면 첫 업데이트 콜백에서) 한 번 명시적으로 이동시켜준다.
        func moveToCurrentLocationIfAvailable() {
            guard !hasMovedToInitialLocation, let mapView else { return }
            guard let current = NMFLocationManager.sharedInstance().currentLatLng(),
                  current.lat != 0 || current.lng != 0 else { return }
            hasMovedToInitialLocation = true
            Task { @MainActor in
                await mapView.moveCamera(NMFCameraUpdate(scrollTo: current))
            }
        }

        nonisolated func locationManager(_ locationManager: NMFLocationManager, didUpdateLocations locations: [Any]) {
            Task { @MainActor in
                self.moveToCurrentLocationIfAvailable()
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        nonisolated func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            // 터치가 마커 근처에서 시작할 때만 내 드래그 제스처가 받는다 — 그 외엔
            // 이 제스처가 즉시 실패해서(require(toFail:)) 지도 자체의 팬이 정상 동작한다.
            MainActor.assumeIsolated {
                guard let mapView else { return false }
                let location = touch.location(in: mapView)
                return self.nearestMarkerIndex(to: location, within: 28) != nil
            }
        }
    }
}
