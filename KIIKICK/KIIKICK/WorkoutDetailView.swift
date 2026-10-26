//
//  WorkoutDetailView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import Charts

struct WorkoutDetailView: View {
    let record: WorkoutRecord

    private let windowLength: TimeInterval = 10

    @State private var showAllPoints = true
    @State private var playbackOffset: TimeInterval = 0
    @State private var isPlaying = false
    @State private var playbackTask: Task<Void, Never>?

    private var maxOffset: TimeInterval {
        max(0, record.duration - windowLength)
    }

    private var windowAnchor: Date? {
        record.points.first?.timestamp
    }

    private var windowedPoints: [TrackPoint] {
        guard let anchor = windowAnchor else { return [] }
        let windowStart = anchor.addingTimeInterval(playbackOffset)
        let windowEnd = windowStart.addingTimeInterval(windowLength)
        return record.points.filter { $0.timestamp >= windowStart && $0.timestamp < windowEnd }
    }

    private var windowedHeartRateSamples: [HeartRateSample] {
        guard let anchor = windowAnchor else { return [] }
        let windowStart = anchor.addingTimeInterval(playbackOffset)
        let windowEnd = windowStart.addingTimeInterval(windowLength)
        return record.heartRateSamples.filter { $0.timestamp >= windowStart && $0.timestamp < windowEnd }
    }

    private var displayedPoints: [TrackPoint] {
        showAllPoints ? record.points : windowedPoints
    }

    private var displayedHeartRateSamples: [HeartRateSample] {
        showAllPoints ? record.heartRateSamples : windowedHeartRateSamples
    }

    private var heartRateDateRange: ClosedRange<Date> {
        let start = record.date
        let end = record.date.addingTimeInterval(max(record.duration, 1))
        return start...end
    }

    private func play() {
        showAllPoints = false
        guard !isPlaying else { return }

        isPlaying = true
        playbackTask = Task {
            while !Task.isCancelled && playbackOffset < maxOffset {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { break }
                playbackOffset = min(maxOffset, playbackOffset + 0.1)
            }
            isPlaying = false
        }
    }

    private func stop() {
        playbackTask?.cancel()
        isPlaying = false
    }

    private func resetToAllPoints() {
        playbackTask?.cancel()
        isPlaying = false
        showAllPoints = true
        playbackOffset = 0
    }

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
            latitudeDelta: max(maxLat - minLat, 0.0006) * 1.2,
            longitudeDelta: max(maxLng - minLng, 0.0006) * 1.2
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Map(initialPosition: .region(region)) {
                    ForEach(displayedPoints, id: \.timestamp) { point in
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("구간 재생")
                        .font(.headline)
                    HStack {
                        Button(action: play) {
                            Image(systemName: "play.fill")
                        }
                        .disabled(record.points.isEmpty || isPlaying)

                        Button(action: stop) {
                            Image(systemName: "stop.fill")
                        }
                        .disabled(!isPlaying)

                        Button(action: resetToAllPoints) {
                            Image(systemName: "xmark")
                        }
                        .disabled(showAllPoints)

                        Slider(value: $playbackOffset, in: 0...max(maxOffset, 0.001))
                            .disabled(record.points.isEmpty)
                    }
                }

                HStack(spacing: 12) {
                    StatTile(title: "칼로리", value: "\(Int(record.totalCalories)) kcal")
                    StatTile(title: "거리", value: "\(Int(record.totalDistance)) m")
                    StatTile(title: "시간", value: "\(Int(record.duration / 60)) 분")
                }

                Text("심박수")
                    .font(.headline)

                Chart(displayedHeartRateSamples, id: \.timestamp) { sample in
                    LineMark(
                        x: .value("시간", sample.timestamp),
                        y: .value("BPM", sample.bpm)
                    )
                }
                .chartXScale(domain: heartRateDateRange)
                .frame(height: 160)
            }
            .padding()
        }
        .navigationTitle(record.date.formatted(date: .abbreviated, time: .shortened))
        .onDisappear { playbackTask?.cancel() }
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
