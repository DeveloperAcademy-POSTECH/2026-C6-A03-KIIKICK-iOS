//
//  FieldRegistrationView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import SwiftData

struct FieldRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pins: [CLLocationCoordinate2D] = []
    @State private var fieldName: String = ""
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(spacing: 12) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
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
            .frame(height: 360)

            Text("\(pins.count)/4 지점 선택됨")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("마지막 핀 취소") {
                    if !pins.isEmpty { pins.removeLast() }
                }
                .disabled(pins.isEmpty)

                Spacer()

                Button("초기화") { pins.removeAll() }
                    .disabled(pins.isEmpty)
            }

            if pins.count == 4 {
                TextField("운동장 이름", text: $fieldName)
                    .textFieldStyle(.roundedBorder)

                Button("저장") { save() }
                    .disabled(fieldName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("운동장 등록")
    }

    private func save() {
        guard pins.count == 4 else { return }
        let field = Field(
            name: fieldName,
            cornerA: FieldCorner(latitude: pins[0].latitude, longitude: pins[0].longitude),
            cornerB: FieldCorner(latitude: pins[1].latitude, longitude: pins[1].longitude),
            cornerC: FieldCorner(latitude: pins[2].latitude, longitude: pins[2].longitude),
            cornerD: FieldCorner(latitude: pins[3].latitude, longitude: pins[3].longitude)
        )
        modelContext.insert(field)
        try? modelContext.save()
        dismiss()
    }
}
