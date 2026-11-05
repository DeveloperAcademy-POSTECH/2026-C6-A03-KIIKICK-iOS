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
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                }
                .ignoresSafeArea()
                ResizableRectangleView()
            }
        }
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
    let (a, b) = rect.goalEdges
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
    @State private var rect = CGRect(x: 100, y: 200, width: 200, height: 150)
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
    FieldCreationView()
}
