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
    
    func point(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX + rect.width  / 2 * sign.x,
                y: rect.midY + rect.height / 2 * sign.y)
    }
}


// MARK: - View
 
struct ResizableRectangleView: View {
    
    // 사걱형의 크기와 위치 정보
    @State private var rect = CGRect(x: 100, y: 200, width: 200, height: 150)
    @State private var startRect: CGRect?
    
    private let minSize: CGFloat = 40
    private let handleSize: CGFloat = 20
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.blue.opacity(0.25))
                .overlay(Rectangle().stroke(.blue, lineWidth: 2))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .gesture(drag)
            ForEach(Corner.allCases, id: \.self) { corner in
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(.blue, lineWidth: 2))
                    .frame(width: handleSize, height: handleSize)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .position(corner.point(in: rect))
                    .gesture(resizeGesture(corner: corner))
            }
            ForEach(Edge.allCases, id: \.self) { edge in
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(.blue, lineWidth: 2))
                    .frame(width: handleSize, height: handleSize)
                    .frame(width: 44, height: 44)
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
