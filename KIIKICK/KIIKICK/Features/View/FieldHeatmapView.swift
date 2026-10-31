//
//  FieldHeatmapView.swift
//  KIIKICK
//

import SwiftUI
import CoreLocation

struct FieldHeatmapView: View {
    let field: Field
    let points: [TrackPoint]
    let renderer: HeatmapRenderer
    
    init(field: Field, points: [TrackPoint], renderer: HeatmapRenderer = GridDensityHeatmapRenderer()) {
        self.field = field
        self.points = points
        self.renderer = renderer
    }
    
    var body: some View {
        let mapper = FieldCoordinateMapper(field: field)
        let normalizedPoints = points.map {
            mapper.normalize(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
        }
        
        FieldCanvasView { context, size in
            renderer.render(in: context, size: size, normalizedPoints: normalizedPoints)
        }
    }
}
