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

    enum SendState {
        case idle
        case sending
        case success
        case failure(String)
    }
    @State private var sendState: SendState = .idle
    
    private var isSending: Bool {
        if case .sending = sendState { return true }
        return false
    }

    private func sendToServer() async {
        guard let userId = UserSession.userId else {
            sendState = .failure("로그인이 필요합니다.")
            return
        }

        sendState = .sending

        let payload = WorkoutPayload(
            startDate: record.date,
            endDate: record.date.addingTimeInterval(record.duration),
            points: record.points,
            heartRateSamples: record.heartRateSamples,
            totalCalories: record.totalCalories,
            totalDistance: record.totalDistance
        )

        do {
            _ = try await WorkoutAPI.upload(userId: userId, payload: payload)
            sendState = .success
        } catch let APIError.serverError(_, message) {
            sendState = .failure(message ?? "전송에 실패했습니다.")
        } catch {
            sendState = .failure("전송에 실패했습니다.")
        }
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
                
                // 경기 정보 전송
                VStack(alignment: .leading, spacing: 8) {
                    Text("경기 정보 전송")
                        .font(.headline)

                    Button {
                        Task { await sendToServer() }
                    } label: {
                        if case .sending = sendState {
                            ProgressView()
                        } else {
                            Text("서버로 전송")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSending)

                    switch sendState {
                    case .idle, .sending:
                        EmptyView()
                    case .success:
                        Label("전송 완료", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failure(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }

                    if UserSession.userId == nil {
                        Text("로그인 후 전송할 수 있어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

#if DEBUG
#Preview {
    WorkoutDetailView(record: WorkoutRecord(payload: .fake()))
}
#endif
