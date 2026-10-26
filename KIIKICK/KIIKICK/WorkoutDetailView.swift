//
//  WorkoutDetailView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import Charts

struct WorkoutDetailView: View {
    let record: WorkoutRecord

    private var region: MKCoordinateRegion {
        let lats = record.points.map(\.latitude)
        let lngs = record.points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.003) * 1.4,
            longitudeDelta: max(maxLng - minLng, 0.003) * 1.4
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Map(initialPosition: .region(region)) {
                    ForEach(Array(record.points.enumerated()), id: \.offset) { index, point in
                        Marker(
                            "\(index + 1)",
                            coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                        )
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    StatTile(title: "칼로리", value: "\(Int(record.totalCalories)) kcal")
                    StatTile(title: "거리", value: "\(Int(record.totalDistance)) m")
                    StatTile(title: "시간", value: "\(Int(record.duration / 60)) 분")
                }

                Text("심박수")
                    .font(.headline)

                Chart(record.heartRateSamples, id: \.timestamp) { sample in
                    LineMark(
                        x: .value("시간", sample.timestamp),
                        y: .value("BPM", sample.bpm)
                    )
                }
                .frame(height: 160)
            }
            .padding()
        }
        .navigationTitle(record.date.formatted(date: .abbreviated, time: .shortened))
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }
}
