//
//  WorkoutDetailView.swift
//  KIIKICK
//

import SwiftUI
import MapKit
import Charts
import SwiftData

struct WorkoutDetailView: View {
    let record: WorkoutRecord
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Field.name) private var fields: [Field]
    @State private var isPresentingFieldPicker = false
    
    private let windowLength: TimeInterval = 10
    
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
    
    private var heartRateDateRange: ClosedRange<Date> {
        let start = record.date
        let end = record.date.addingTimeInterval(max(record.duration, 1))
        return start...end
    }
    
    private func play() {
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
                
                // 경기장
                if let field = record.field {
                    TabView {
                        GeometryReader { geo in
                            VStack {
                                Text("히트맵")
                                    .font(.headline)
                                FieldHeatmapView(field: field, points: record.points)
                                    .frame(width: geo.size.width, height: geo.size.width * 68 / 105)
                            }
                        }
                        GeometryReader { geo in
                            VStack {
                                Text("스프린트")
                                    .font(.headline)
                                SprintMapView(field: field, points: record.points)
                                    .frame(width: geo.size.width, height: geo.size.width * 68 / 105)
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(.page)                         // 좌우 스와이프 페이징
                    .indexViewStyle(.page(backgroundDisplayMode: .always)) // 하단 점 표시
                }
                
                // 운동장 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동장")
                        .font(.headline)
                    Button(record.field?.name ?? "운동장을 선택해주세요") {
                        isPresentingFieldPicker = true
                    }
                }
                
                // 주요 스탯
                GeometryReader { geo in
                    HStack(spacing: 24) {
                        ZStack {
                            VStack {
                                Text("최고 속도")
                            }
                        }
                        .frame(width: (geo.size.width - 48) / 3, height: (geo.size.width - 48) / 3)
                        
                        ZStack {
                            VStack {
                                Text("이동 거리")
                            }
                        }
                        .frame(width: (geo.size.width - 48) / 3, height: (geo.size.width - 48) / 3)
                        
                        ZStack {
                            VStack {
                                Text("소모 칼로리")
                            }
                        }
                        .frame(width: (geo.size.width - 48) / 3, height: (geo.size.width - 48) / 3)
                    }
                }
                .frame(height: 110)
                
                // 움직임
                VStack(alignment: .leading, spacing: 18) {
                    Text("움직임")
                        .font(.title3)
                        .fontWeight(.bold)
                    HStack {
                        Text("평균 속력")
                        Text("")
                    }
                    HStack {
                        Text("고강도 주행거리")
                        Text("")
                    }
                    HStack {
                        Text("방향 전환 횟수")
                        Text("")
                    }
                    HStack {
                        Text("가속 횟수")
                        Text("")
                        Text("감속 횟수")
                        Text("")
                    }
                }
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("신체 활동")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("최대 심박수")
                        Text("")
                        Text("평균 심박수")
                        Text("")
                    }
                }
                .padding([.top], 60)
                
                VStack(alignment: .leading, spacing: 18) {
                    Text("훈련 부하지수")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("TRIMP")
                        Text("")
                    }
                    
                    HStack {
                        Text("Player Load")
                        Text("")
                    }
                }
                .padding([.top], 60)
                
                Divider()
            }
            .padding([.horizontal], 24)
        }
        .navigationTitle(record.date.formatted(date: .abbreviated, time: .shortened))
        .onDisappear { playbackTask?.cancel() }
        .sheet(isPresented: $isPresentingFieldPicker) {
            NavigationStack {
                List(fields) { field in
                    Button(field.name) {
                        record.field = field
                        try? modelContext.save()
                        isPresentingFieldPicker = false
                    }
                }
                .overlay {
                    if fields.isEmpty {
                        Text("등록된 운동장이 없습니다")
                            .foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("운동장 선택")
            }
        }
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

#Preview {
    WorkoutDetailView(record: WorkoutRecord(payload: .fake()))
}
