//
//  FieldCreationView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import MapKit
import SwiftData
import SwiftUI

struct FieldCreationView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var pins: [CLLocationCoordinate2D] = []
    @State private var fieldName: String = ""
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                        ForEach(Array(pins.enumerated()), id: \.offset) { index, coordinate in
                            Marker("\(index + 1)", coordinate: coordinate)
                        }
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { event in
                                guard pins.count < 4,
                                      let coordinate = proxy.convert(event.location, from: .local) else { return }
                                pins.append(coordinate)
                            }
                    )
                }
                .ignoresSafeArea()            }
        }
    }
}

#Preview {
    FieldCreationView()
}
