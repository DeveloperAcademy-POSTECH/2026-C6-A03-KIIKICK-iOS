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

        Canvas { context, size in
            // 1. 배경
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

            // 2~3. 히트맵
            renderer.render(in: context, size: size, normalizedPoints: normalizedPoints)

            // 4. 필드 테두리
            context.stroke(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white),
                lineWidth: 2
            )
        }
        .aspectRatio(105.0 / 68.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
