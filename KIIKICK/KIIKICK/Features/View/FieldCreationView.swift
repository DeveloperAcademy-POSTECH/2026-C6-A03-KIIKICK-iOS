//
//  FieldCreationView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//
//  Figma node 256:1018 "newfield_02" (경기장 등록 — 사각형 조정 단계)
//
//  DESIGN-GAP: 골대 박스의 정확한 치수(폭/깊이 비율)는 Figma 목업(526:3137 "Match Map
//  Viewer")이 단순화된 미리보기라 실측값이 없어, 실제 축구 페널티 박스 비율(가로 약
//  59%, 세로 약 16%)을 근사해 하드코딩했다.
//
//  DESIGN-GAP: "운동시설만" 검색되게 거르는 기준은 Figma에 명시가 없어, MapKit의
//  POI 카테고리 중 운동 시설에 해당하는 .stadium / .fitnessCenter 두 개로 좁혔다.
//  (.park는 범위가 너무 넓어 제외)
//

import MapKit
import SwiftData
import SwiftUI

struct FieldCreationView: View {

    @Environment(\.dismiss) private var dismiss

    /// 등록(저장 또는 취소)이 끝나 이 플로우 전체를 닫아야 할 때 호출된다.
    var onFinish: () -> Void = {}

    @State private var rect = CGRect(x: 100, y: 200, width: 200, height: 150)
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    @State private var coordinates: [CLLocationCoordinate2D] = []
    @State private var goNext = false

    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var searchTask: Task<Void, Never>?

    /// 사각형 네 꼭짓점을 위경도로 변환할 때의 기준 순서. 저장되는 cornerA~D도 항상
    /// 이 시계방향 순서를 따른다 (AGENTS.md: 핀 순서를 일관된 규칙으로 저장).
    private let cornerOrder: [Corner] = [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading]

    private let sportsFacilityFilter = MKPointOfInterestFilter(including: [.stadium, .fitnessCenter])

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                }
                .mapStyle(.imagery(elevation: .realistic))
                .ignoresSafeArea()

                ResizableRectangleView(rect: $rect)

                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        SearchBarView(
                            text: $searchQuery,
                            placeholder: "운동장 검색",
                            state: searchQuery.isEmpty ? .default : .writing,
                            onClear: { searchQuery = ""; searchResults = [] }
                        )

                        if !searchResults.isEmpty {
                            searchResultsList
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    infoBanner
                        .padding(.top, 12)

                    Spacer()
                }

                CtaView(text: "추가", type: .primary, size: .large) {
                    coordinates = cornerOrder.compactMap { proxy.convert($0.point(in: rect), from: .local) }
                    goNext = coordinates.count == 4
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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
            FieldNamingView(coordinates: coordinates, onFinish: onFinish)
        }
    }

    private var infoBanner: some View {
        Text("경기장을 사각형에 맞추어 조정해주세요")
            .font(.body3R)
            .foregroundStyle(.gray50)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.gray950)
    }

    private var searchResultsList: some View {
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
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if index != searchResults.count - 1 {
                    Rectangle().fill(Color.gray800).frame(height: 1)
                }
            }
        }
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
    }

    private func search(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = .pointOfInterest
            request.pointOfInterestFilter = sportsFacilityFilter
            guard let response = try? await MKLocalSearch(request: request).start(),
                  !Task.isCancelled else { return }
            searchResults = response.mapItems
        }
    }

    private func select(_ item: MKMapItem) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
            )
        }
        searchQuery = item.name ?? ""
        searchResults = []
    }
}

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var sign: (x: CGFloat, y: CGFloat) {
        switch self {
        case .topLeading:     (-1, -1)
        case .topTrailing:    ( 1, -1)
        case .bottomLeading:  (-1,  1)
        case .bottomTrailing: ( 1,  1)
        }
    }

    func point(in rect: CGRect) -> CGPoint {
        CGPoint(x: sign.x < 0 ? rect.minX : rect.maxX,
                y: sign.y < 0 ? rect.minY : rect.maxY)
    }
}

private enum Edge: CaseIterable {
    case top, bottom, leading, trailing

    var sign: (x: CGFloat, y: CGFloat) {

        switch self {
        case .top:      ( 0, -1)
        case .bottom:   ( 0,  1)
        case .leading:  (-1,  0)
        case .trailing: ( 1,  0)
        }
    }

    var isHorizontal: Bool { self == .top || self == .bottom }

    func point(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX + rect.width  / 2 * sign.x,
                y: rect.midY + rect.height / 2 * sign.y)
    }
}


// MARK: - Pitch markings (골대 + 중앙선)

/// 가로/세로 중 더 짧은 한 쌍의 변을 골라인으로 삼는다. 사각형을 조정해 가로세로가
/// 뒤바뀌면(위 아래 변이 양 옆보다 짧아지면) 골대와 중앙선도 자동으로 90도 돌아간다.
private extension CGRect {
    var goalEdges: (Edge, Edge) {
        width >= height ? (.leading, .trailing) : (.top, .bottom)
    }
}

private func centerLinePath(in rect: CGRect) -> Path {
    var path = Path()
    let (a, _) = rect.goalEdges
    // 중앙선은 골대가 있는 변과 수직인, 골대가 없는 변의 중점끼리 잇는다.
    let (from, to) = a.isHorizontal
        ? (Edge.leading.point(in: rect), Edge.trailing.point(in: rect))
        : (Edge.top.point(in: rect), Edge.bottom.point(in: rect))
    path.move(to: from)
    path.addLine(to: to)
    return path
}

private func goalBoxPath(at edge: Edge, in rect: CGRect) -> Path {
    let span = (edge.isHorizontal ? rect.width : rect.height) * 0.5
    let depth = (edge.isHorizontal ? rect.height : rect.width) * 0.16
    let center = edge.point(in: rect)
    let sign = edge.sign
    let half = span / 2

    var path = Path()
    if edge.isHorizontal {
        let inwardY = center.y - sign.y * depth
        path.move(to: CGPoint(x: center.x - half, y: center.y))
        path.addLine(to: CGPoint(x: center.x - half, y: inwardY))
        path.addLine(to: CGPoint(x: center.x + half, y: inwardY))
        path.addLine(to: CGPoint(x: center.x + half, y: center.y))
    } else {
        let inwardX = center.x - sign.x * depth
        path.move(to: CGPoint(x: center.x, y: center.y - half))
        path.addLine(to: CGPoint(x: inwardX, y: center.y - half))
        path.addLine(to: CGPoint(x: inwardX, y: center.y + half))
        path.addLine(to: CGPoint(x: center.x, y: center.y + half))
    }
    return path
}

private struct PitchMarkingsView: View {
    let rect: CGRect

    var body: some View {
        let (goalA, goalB) = rect.goalEdges
        Canvas { context, _ in
            let style = StrokeStyle(lineWidth: 2, lineCap: .round)
            context.stroke(centerLinePath(in: rect), with: .color(.white.opacity(0.9)), style: style)
            context.stroke(goalBoxPath(at: goalA, in: rect), with: .color(.white.opacity(0.9)), style: style)
            context.stroke(goalBoxPath(at: goalB, in: rect), with: .color(.white.opacity(0.9)), style: style)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Handle shapes (Photos 앱 크롭 UI 참고)

private struct CornerBracket: Shape {
    let corner: Corner
    let armLength: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let dx = corner.sign.x * armLength
        let dy = corner.sign.y * armLength
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y + dy))
        path.addLine(to: c)
        path.addLine(to: CGPoint(x: c.x + dx, y: c.y))
        return path
    }
}

private struct EdgeTick: Shape {
    let edge: Edge
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        if edge.isHorizontal {
            path.move(to: CGPoint(x: c.x - length / 2, y: c.y))
            path.addLine(to: CGPoint(x: c.x + length / 2, y: c.y))
        } else {
            path.move(to: CGPoint(x: c.x, y: c.y - length / 2))
            path.addLine(to: CGPoint(x: c.x, y: c.y + length / 2))
        }
        return path
    }
}

// MARK: - View

struct ResizableRectangleView: View {

    // 사걱형의 크기와 위치 정보
    @Binding var rect: CGRect
    @State private var startRect: CGRect?

    private let minSize: CGFloat = 40
    private let handleTouchSize: CGFloat = 44

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .overlay(Rectangle().stroke(Color.white, lineWidth: 3))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .gesture(drag)

            PitchMarkingsView(rect: rect)

            ForEach(Corner.allCases, id: \.self) { corner in
                CornerBracket(corner: corner, armLength: 14)
                    .stroke(Color.mint500, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: handleTouchSize, height: handleTouchSize)
                    .contentShape(Rectangle())
                    .position(corner.point(in: rect))
                    .gesture(resizeGesture(corner: corner))
            }
            ForEach(Edge.allCases, id: \.self) { edge in
                EdgeTick(edge: edge, length: 20)
                    .stroke(Color.mint500, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: handleTouchSize, height: handleTouchSize)
                    .contentShape(Rectangle())
                    .position(edge.point(in: rect))
                    .gesture(resizeGesture(edge: edge))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named("canvas"))
    }

    // MARK: - Gesture

    var drag: some Gesture {
        DragGesture()
          .onChanged { gesture in
              if startRect == nil { startRect = rect }
              guard let start = startRect else { return }
              rect = reposition(start, translation: gesture.translation)
          }
          .onEnded { gesture in
            startRect = nil
          }
      }

    private func resizeGesture(corner: Corner) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                if startRect == nil { startRect = rect } // 드래그 시작 시 rect를 한 번만 저장
                guard let start = startRect else { return }
                rect = resized(start, sign: corner.sign, translation: value.translation)
            }
            .onEnded { _ in
                startRect = nil
            }
    }

    private func resizeGesture(edge: Edge) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                if startRect == nil { startRect = rect }
                guard let start = startRect else { return }
                rect = resized(start, sign: edge.sign, translation: value.translation)
            }
            .onEnded { _ in
                startRect = nil
            }
    }

    private func reposition(_ start: CGRect, translation: CGSize) -> CGRect {
        start.offsetBy(dx: translation.width, dy: translation.height)
    }

    private func resized(_ start: CGRect, sign s: (x: CGFloat, y: CGFloat), translation: CGSize) -> CGRect {
        // 1. 반대편 변 = 고정 변
        let fixedX = s.x < 0 ? start.maxX : start.minX
        let fixedY = s.y < 0 ? start.maxY : start.minY

        // 2. 드래그 방향을 부호로 보정해서 새 크기 계산 (최소 크기 보장)
        let width  = max(minSize, start.width  + translation.width  * s.x)
        let height = max(minSize, start.height + translation.height * s.y)

        // 3. 고정점 기준으로 origin 다시 계산
        let x = s.x < 0 ? fixedX - width  : fixedX
        let y = s.y < 0 ? fixedY - height : fixedY

        return CGRect(x: x, y: y, width: width, height: height)
    }
}

extension CGSize {
  static func + (lhs: Self, rhs: Self) -> Self {
    CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
  }
}

#Preview {
    NavigationStack {
        FieldCreationView()
    }
}
