//
//  FieldCreationView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//
//  핀 4개를 순서 상관없이 탭해서 찍는 방식. 직사각형 프레임 UI(ResizableRectangleView)는
//  제거했다 — 직사각형으로 맞추는 건 FieldRectangleCorrector가 등록 시점에 한 번만
//  계산한다(docs/superpowers/specs/2026-11-06-field-rectangle-correction-design.md).
//  FieldRectangleCorrector가 중앙값 기준으로 알아서 둘레 순서를 다시 매기기 때문에,
//  사용자가 어떤 순서로 찍어도(대각선으로 건너뛰어도) 결과가 똑같다 — 그래서 이 화면은
//  "몇 번째 핀"이라는 문구는 보여줘도 "어느 방향으로 찍어야 한다" 같은 순서 안내는 하지
//  않는다.
//
//  DESIGN-GAP: "운동시설만" 검색되게 거르는 기준은 Figma에 명시가 없어, MapKit의
//  POI 카테고리 중 운동 시설에 해당하는 .stadium / .fitnessCenter 두 개로 좁혔다.
//  (.park는 범위가 너무 넓어 제외)
//
//  DESIGN-GAP: MKLocalSearch.Request에는 검색 결과 언어를 강제하는 파라미터가 없다.
//  대신 검색 영역을 한국으로 한정해서(region 힌트 + countryCode 필터) 한국 내
//  운동시설만 나오게 했고, 그 데이터 자체가 한글 이름으로 등록돼 있어 실질적으로
//  한글 결과가 나온다.
//
//  DESIGN-GAP: 돋보기는 진짜 픽셀 확대가 아니라, 드래그 중인 핀의 실시간 좌표를
//  중심으로 한 별도의 작은 확대 Map을 띄우는 방식이다 — MapKit이 특정 화면 영역만
//  픽셀 단위로 확대해 보여주는 API를 제공하지 않기 때문.
//

import MapKit
import SwiftData
import SwiftUI

struct FieldCreationView: View {

    @Environment(\.dismiss) private var dismiss

    /// 등록(저장 또는 취소)이 끝나 이 플로우 전체를 닫아야 할 때 호출된다.
    var onFinish: () -> Void = {}

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    @State private var goNext = false

    /// 사용자가 찍은 원본 핀. 최대 4개. 찍은 순서는 FieldRectangleCorrector가 중앙값
    /// 기준으로 다시 매기므로 의미가 없다 — "몇 번째 핀을 찍었는지" 안내용으로만 쓴다.
    @State private var rawPinCoordinates: [CLLocationCoordinate2D] = []

    @State private var draggingIndex: Int?
    @State private var isMagnifying = false
    @State private var magnifierCoordinate: CLLocationCoordinate2D?
    @State private var magnifierAnchor: CGPoint = .zero

    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var isPresentingResults = false

    private let sportsFacilityFilter = MKPointOfInterestFilter(including: [.stadium, .fitnessCenter])
    private let southKoreaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.9, longitude: 128.2),
        span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 7.5)
    )

    private var guidanceText: String {
        switch rawPinCoordinates.count {
        case 0: return "운동장 꼭짓점을 탭해서 1번째 핀을 찍어주세요"
        case 1: return "2번째 핀을 찍어주세요"
        case 2: return "3번째 핀을 찍어주세요"
        case 3: return "4번째 핀을 찍어주세요"
        default: return "핀을 눌러서 꾹 누르면 돋보기로 미세 조정할 수 있어요"
        }
    }

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                }
                .mapStyle(.imagery(elevation: .realistic))
                .ignoresSafeArea()

                // Map이 ignoresSafeArea라서 이것도 똑같이 걸어둬야 한다 — 그렇지 않으면
                // 이 뷰의 로컬 좌표 원점이 safe area(상태바+네비바)만큼 Map과 어긋나서,
                // proxy.convert(_:from: .local)이 핀의 실제 화면 위치와 다른 엉뚱한
                // 위경도를 돌려준다(저장/스냅샷에서 "좌표가 밀린" 것처럼 보이는 원인).
                pinField(proxy: proxy)
                    .ignoresSafeArea()
                    .coordinateSpace(.named("pinField"))

                VStack(spacing: 0) {
                    SearchBarView(
                        text: $searchQuery,
                        placeholder: "운동장 검색",
                        state: searchQuery.isEmpty ? .default : .writing,
                        onClear: { searchQuery = ""; searchResults = []; isPresentingResults = false }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    guidanceBanner
                        .padding(.top, 12)

                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        if !rawPinCoordinates.isEmpty {
                            undoButton
                        }
                        Spacer()
                        myLocationButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)

                CtaView(text: "추가", type: .primary, size: .large, isActive: rawPinCoordinates.count == 4) {
                    goNext = rawPinCoordinates.count == 4
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                if isMagnifying, let magnifierCoordinate {
                    MagnifierView(coordinate: magnifierCoordinate)
                        .frame(width: 110, height: 110)
                        .position(x: magnifierAnchor.x, y: max(70, magnifierAnchor.y - 90))
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .navigationTitle("경기장 등록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .onChange(of: searchQuery) { _, newValue in
            search(for: newValue)
        }
        .navigationDestination(isPresented: $goNext) {
            FieldNamingView(rawCoordinates: rawPinCoordinates, onFinish: onFinish)
        }
        .sheet(isPresented: $isPresentingResults) {
            searchResultsSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.gray950)
        }
    }

    // MARK: - 핀 필드 (탭으로 배치, 드래그로 조정)

    @ViewBuilder
    private func pinField(proxy: MapProxy) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("pinField"))
                        .onEnded { value in
                            guard rawPinCoordinates.count < 4,
                                  let coordinate = proxy.convert(value.location, from: .local) else { return }
                            rawPinCoordinates.append(coordinate)
                        }
                )

            pinLoopPreview(proxy: proxy)
                .allowsHitTesting(false)

            ForEach(Array(rawPinCoordinates.enumerated()), id: \.offset) { index, coordinate in
                if let point = proxy.convert(coordinate, to: .local) {
                    pinHandle(number: index + 1)
                        .position(point)
                        .gesture(pinDragGesture(index: index, proxy: proxy))
                }
            }
        }
    }

    private func pinDragGesture(index: Int, proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("pinField")))
            .onChanged { value in
                switch value {
                case .first(true):
                    draggingIndex = index
                    withAnimation(.easeOut(duration: 0.15)) { isMagnifying = true }
                case .second(true, let drag):
                    guard let drag, let coordinate = proxy.convert(drag.location, from: .local) else { return }
                    rawPinCoordinates[index] = coordinate
                    magnifierCoordinate = coordinate
                    magnifierAnchor = drag.location
                default:
                    break
                }
            }
            .onEnded { _ in
                draggingIndex = nil
                withAnimation(.easeIn(duration: 0.15)) { isMagnifying = false }
            }
    }

    private func pinLoopPreview(proxy: MapProxy) -> some View {
        Canvas { context, _ in
            let points = rawPinCoordinates.compactMap { proxy.convert($0, to: .local) }
            guard points.count >= 2 else { return }
            var path = Path()
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
            if points.count == 4 { path.closeSubpath() }

            context.stroke(path, with: .color(.mint500.opacity(0.8)), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            if points.count == 4 {
                context.fill(path, with: .color(.mint500.opacity(0.12)))
            }
        }
    }

    private func pinHandle(number: Int) -> some View {
        ZStack {
            Circle().fill(Color.gray950).frame(width: 28, height: 28)
            Circle().stroke(Color.mint500, lineWidth: 3).frame(width: 28, height: 28)
            Text("\(number)")
                .font(.caption1M)
                .foregroundStyle(.mint500)
        }
        .contentShape(Circle().inset(by: -8)) // 터치 영역을 살짝 넓힘
    }

    private var undoButton: some View {
        Button {
            _ = rawPinCoordinates.popLast()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 16))
                .foregroundStyle(.gray50)
                .frame(width: 44, height: 44)
                .background(Color.gray900, in: Circle())
                .overlay(Circle().stroke(Color.gray700, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var guidanceBanner: some View {
        Text(guidanceText)
            .font(.body3R)
            .foregroundStyle(.gray50)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.gray950)
            .padding(.horizontal, 16)
    }

    private var myLocationButton: some View {
        Button {
            withAnimation { cameraPosition = .userLocation(fallback: .automatic) }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18))
                .foregroundStyle(.gray50)
                .frame(width: 44, height: 44)
                .background(Color.gray900, in: Circle())
                .overlay(Circle().stroke(Color.gray700, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var searchResultsSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("검색 결과 \(searchResults.count)")
                .font(.label4SB)
                .foregroundStyle(.gray400)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(searchResults.enumerated()), id: \.offset) { index, item in
                        Button {
                            select(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "")
                                    .font(.body1M)
                                    .foregroundStyle(.gray50)
                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption1M)
                                        .foregroundStyle(.gray400)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        if index != searchResults.count - 1 {
                            Rectangle().fill(Color.gray800).frame(height: 1)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
    }

    private func search(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            isPresentingResults = false
            return
        }
        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = .pointOfInterest
            request.pointOfInterestFilter = sportsFacilityFilter
            request.region = southKoreaRegion
            guard let response = try? await MKLocalSearch(request: request).start(),
                  !Task.isCancelled else { return }
            // region은 결과를 "그쪽으로 치우치게" 할 뿐 한국 밖 결과를 완전히 막지는
            // 않아서, countryCode로 한 번 더 걸러 한국 내 결과만 남긴다.
            let results = response.mapItems.filter { $0.placemark.countryCode == "KR" }
            searchResults = results
            isPresentingResults = !results.isEmpty
        }
    }

    private func select(_ item: MKMapItem) {
        isPresentingResults = false
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
            )
        }
        searchQuery = item.name ?? ""
        searchResults = []
    }
}

/// 핀을 꾹 눌러 드래그하는 동안 뜨는 확대경. 실제 화면을 픽셀 단위로 확대하는 게
/// 아니라, 드래그 중인 좌표를 중심으로 한 별도의 작은 확대 Map을 띄우는 방식이다.
private struct MagnifierView: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        ZStack {
            Map(position: .constant(.region(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 30, longitudinalMeters: 30)
            )), interactionModes: [])
            .mapStyle(.imagery(elevation: .realistic))
            .allowsHitTesting(false)

            Circle()
                .stroke(Color.mint500, lineWidth: 2)
                .frame(width: 10, height: 10)
            Rectangle().fill(Color.mint500).frame(width: 1.5, height: 16)
            Rectangle().fill(Color.mint500).frame(width: 16, height: 1.5)
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
    }
}

#Preview {
    NavigationStack {
        FieldCreationView()
    }
}
