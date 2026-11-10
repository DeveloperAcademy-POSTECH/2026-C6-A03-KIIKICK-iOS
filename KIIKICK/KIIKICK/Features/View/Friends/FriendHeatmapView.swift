//
//  FriendHeatmapView.swift
//  KIIKICK
//

import CoreLocation
import SwiftUI

/// 친구 API의 집계 셀을 기존 운동장 이미지 위에 상대 밀도로 그린다.
struct FriendHeatmapView: View {
    let field: Field?
    let heatmap: FriendHeatmapResponse?
    let isAttackDirectionReversed: Bool

    var body: some View {
        if let field, let heatmap {
            let mapper = FieldCoordinateMapper(field: field)
            let transform = AttackDirectionTransform(isReversed: isAttackDirectionReversed)
            let points = heatmap.cells.compactMap { cell -> WeightedHeatmapPoint? in
                guard cell.latitude.isFinite, cell.longitude.isFinite, cell.sampleCount > 0 else { return nil }
                let location = transform.apply(to: mapper.normalize(
                    CLLocationCoordinate2D(latitude: cell.latitude, longitude: cell.longitude)
                ))
                return WeightedHeatmapPoint(location: location, weight: Double(cell.sampleCount))
            }

            FieldCanvasView { context, size in
                GridDensityHeatmapRenderer().render(
                    in: context,
                    size: size,
                    weightedNormalizedPoints: points
                )
            }
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray850)
        }
    }
}
