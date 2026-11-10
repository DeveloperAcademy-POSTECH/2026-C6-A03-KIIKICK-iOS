//
//  FieldHeatmapView.swift
//  KIIKICK
//

import SwiftUI
import CoreLocation

struct FieldHeatmapView: View {
    let field: Field
    let points: [TrackPoint]
    let isAttackDirectionReversed: Bool
    let renderer: HeatmapRenderer
    
    init(field: Field, points: [TrackPoint], isAttackDirectionReversed: Bool = false, renderer: HeatmapRenderer = GridDensityHeatmapRenderer()) {
        self.field = field
        self.points = points
        self.isAttackDirectionReversed = isAttackDirectionReversed
        self.renderer = renderer
    }
    
    var body: some View {
        let mapper = FieldCoordinateMapper(field: field)
        let transform = AttackDirectionTransform(isReversed: isAttackDirectionReversed)
        let normalizedPoints = points.compactMap { point -> CGPoint? in
            guard point.latitude.isFinite, point.longitude.isFinite else { return nil }
            return transform.apply(to: mapper.normalize(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)))
        }
        
        FieldCanvasView { context, size in
            renderer.render(in: context, size: size, normalizedPoints: normalizedPoints)
        }
    }
}
