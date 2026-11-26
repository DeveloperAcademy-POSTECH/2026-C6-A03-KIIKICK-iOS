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
            // 시작해야 locationOverlay/카메라가 따라온다.
            mapView.positionMode = .direction
            NMFLocationManager.sharedInstance().startUpdatingLocation()
        }

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        mapView.addGestureRecognizer(pan)

        context.coordinator.mapView = mapView
        return mapView
    }

    static func dismantleUIView(_ uiView: NMFMapView, coordinator: Coordinator) {
        NMFLocationManager.sharedInstance().stopUpdatingLocation()
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
    final class Coordinator: NSObject, NMFMapViewTouchDelegate, UIGestureRecognizerDelegate {
        private var pins: Binding<[CLLocationCoordinate2D]>
        private var draggingIndex: Binding<Int?>
        private let onTapEmptyMap: (CLLocationCoordinate2D) -> Void
        weak var mapView: NMFMapView?
        private var markers: [NMFMarker] = []
        private var polyline: NMFPolylineOverlay?
        var lastRecenterTrigger = false
        private var draggingMarkerIndex: Int?

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

        // MARK: - UIGestureRecognizerDelegate

        nonisolated func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // 마커를 드래그 중일 땐 지도 자체의 팬(이동)과 동시에 인식되면 안 된다.
            MainActor.assumeIsolated { self.draggingMarkerIndex == nil }
        }
    }
}
