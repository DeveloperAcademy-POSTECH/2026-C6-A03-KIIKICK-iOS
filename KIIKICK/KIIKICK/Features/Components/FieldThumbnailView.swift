//
//  FieldThumbnailView.swift
//  KIIKICK
//
//  네 꼭짓점이 모두 보이는 영역을 지도 스냅샷(NaverMapSnapshotter)으로 렌더링하고 그 위에
//  운동장 경계선을 겹쳐 그린다. "selected field" 카드(Figma node 563:5728 "newfield_03",
//  241:1779/544:4049 "ready")에서 공통으로 쓴다 — Figma 목업 자체는 범용 축구장
//  일러스트를 썼지만(정적 목업이라 실제 지오데이터를 못 담음), 실제 등록된 좌표로 렌더링한
//  실사 스냅샷이 사용자에게 더 유용해서 FieldNamingView가 먼저 쓰던 방식을 공용으로 뺐다.
//

import CoreLocation
import SwiftUI

struct FieldThumbnailView: View {
    let coordinates: [CLLocationCoordinate2D]

    @State private var snapshotImage: UIImage?

    private static let size = CGSize(width: 354, height: 138)

    var body: some View {
        ZStack {
            if let snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray800
                ProgressView()
                    .tint(.mint500)
            }
        }
        .frame(height: 138)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        // .padding(24)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
        .task(id: coordinates) {
            snapshotImage = await NaverMapSnapshotter.renderSnapshot(for: coordinates, size: Self.size)
        }
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

#Preview {
    FieldThumbnailView(coordinates: [
        CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
        CLLocationCoordinate2D(latitude: 37.5, longitude: 127.001),
        CLLocationCoordinate2D(latitude: 37.501, longitude: 127.001),
        CLLocationCoordinate2D(latitude: 37.501, longitude: 127.0),
    ])
    .padding()
    .background(Color.gray950)
}
