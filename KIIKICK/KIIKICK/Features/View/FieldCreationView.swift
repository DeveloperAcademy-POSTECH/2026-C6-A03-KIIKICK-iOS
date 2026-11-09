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
//  1차 구현은 Map 전체를 덮는 투명 오버레이(Color.clear + DragGesture)로 탭 위치를
//  좌표로 바꾸는 방식이었다. 그 오버레이가 터치를 배타적으로 가로채서 Map 자체의
//  핀치줌/팬이 전혀 안 먹혔고, 좌표 변환도 어긋나 핀이 의도하지 않은 곳에 찍히는
//  문제가 있었다(세부 배경은 설계 문서 §1-1). 그래서 오버레이를 걷어내고 Map의 기존
//  컴포넌트를 그대로 쓰는 방식으로 다시 짰다:
//  - 핀 추가: SpatialTapGesture를 Map 자체에 직접 붙인다(별도 오버레이 아님).
//  - 핀 표시/드래그: Map 콘텐츠 빌더 안의 Annotation(coordinate:)으로 올린다. SwiftUI
//    MapKit엔 UIKit의 isDraggable 같은 내장 드래그 API가 없어서, Annotation의 커스텀
//    콘텐츠 뷰 자체에 DragGesture를 붙인다 — 핀 하나 크기 뷰라 지도 전체 제스처와 덜
//    충돌한다.
//  - 핀을 잇는 점선: MapPolyline을 콘텐츠 빌더 안에 넣어서 지도 좌표계에서 직접
//    그린다 — 수동 좌표 변환 없이 팬/줌에 자동으로 따라온다.
//  - 돋보기(loupe) 미세조정 UI와 운동장 검색(MKLocalSearch)은 뺐다 — 돋보기는 오버레이
//    전용 기능이라 네이티브 Annotation 드래그 방향과 안 맞고, 검색은 개발 리소스 대비
//    우선순위가 낮다고 판단.
//

import MapKit
import SwiftUI

struct FieldCreationView: View {

    @Environment(\.dismiss) private var dismiss

    /// 등록을 취소해 이 플로우 전체를 닫아야 할 때 호출된다.
    var onFinish: () -> Void = {}
    /// 등록을 마치고 "경기 준비" 화면(ReadyForMatchView)에서 "준비하기"를 눌렀을 때 호출된다.
    var onFieldPrepared: ((Field) -> Void)? = nil

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    @State private var goNext = false

    /// 사용자가 찍은 원본 핀. 최대 4개. 찍은 순서는 FieldRectangleCorrector가 중앙값
    /// 기준으로 다시 매기므로 의미가 없다 — "몇 번째 핀을 찍었는지" 안내용으로만 쓴다.
    @State private var rawPinCoordinates: [CLLocationCoordinate2D] = []
    @State private var draggingIndex: Int?

    private var guidanceText: String {
        switch rawPinCoordinates.count {
        case 0: return "운동장 꼭짓점을 탭해서 1번째 핀을 찍어주세요"
        case 1: return "2번째 핀을 찍어주세요"
        case 2: return "3번째 핀을 찍어주세요"
        case 3: return "4번째 핀을 찍어주세요"
        default: return "핀을 눌러서 드래그하면 위치를 조정할 수 있어요"
        }
    }

    /// 핀 4개가 다 찍히면 첫 점을 한 번 더 붙여서 폴리라인이 사각형으로 닫히게 한다.
    private var polylineCoordinates: [CLLocationCoordinate2D] {
        rawPinCoordinates.count == 4 ? rawPinCoordinates + [rawPinCoordinates[0]] : rawPinCoordinates
    }

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    if rawPinCoordinates.count >= 2 {
                        MapPolyline(coordinates: polylineCoordinates)
                            .stroke(Color.mint500.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    }

                    ForEach(Array(rawPinCoordinates.enumerated()), id: \.offset) { index, coordinate in
                        Annotation("", coordinate: coordinate) {
                            pinHandle(number: index + 1)
                                .gesture(pinDragGesture(index: index, proxy: proxy))
                        }
                    }
                }
                .mapStyle(.imagery(elevation: .realistic))
                // Map 자체에 직접 붙인다 — 별도 오버레이 뷰를 두면 Map의 네이티브
                // 핀치줌/팬을 가로채 버린다(설계 문서 §1-1 참고).
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard rawPinCoordinates.count < 4,
                                  let coordinate = proxy.convert(value.location, from: .local) else { return }
                            rawPinCoordinates.append(coordinate)
                        }
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
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
        .navigationDestination(isPresented: $goNext) {
            FieldNamingView(rawCoordinates: rawPinCoordinates, onFinish: onFinish, onFieldPrepared: onFieldPrepared)
        }
    }

    // MARK: - 핀 (드래그로 조정)

    /// 핀은 Annotation의 작은 콘텐츠 뷰 안에서 움직이는 게 아니라 Map 전체에 걸쳐
    /// 드래그되므로, 좌표 공간은 Annotation 뷰의 로컬이 아니라 .global을 쓴다 — 중첩
    /// 깊이와 무관하게 항상 같은 기준을 가리키는 유일한 선택지라서다.
    private func pinDragGesture(index: Int, proxy: MapProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                draggingIndex = index
                guard let coordinate = proxy.convert(value.location, from: .global) else { return }
                rawPinCoordinates[index] = coordinate
            }
            .onEnded { _ in draggingIndex = nil }
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
}

#Preview {
    NavigationStack {
        FieldCreationView()
    }
}
