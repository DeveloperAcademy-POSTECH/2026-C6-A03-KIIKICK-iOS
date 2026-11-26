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
//  위성 지도는 Apple Map(MapKit)에서 네이버 지도 SDK로 전환했다(#105) — 일부 지역
//  위성 이미지가 최신화되지 않거나 기울어져 찍혀 있어 꼭짓점을 정확히 찍기 어려운
//  경우가 있었다. 인터랙티브 지도 자체는 NaverMapView(UIViewRepresentable)가
//  담당하고, 이 화면은 기존과 동일한 상태 모델(rawPinCoordinates, draggingIndex,
//  guidanceText, undo/내 위치 버튼)만 유지한다 — 자세한 배경은
//  docs/superpowers/specs/2026-11-26-naver-map-sdk-design.md 참고.
//
//  돋보기(loupe) 미세조정 UI와 운동장 검색(MKLocalSearch)은 뺐다 — 돋보기는 오버레이
//  전용 기능이라 네이티브 마커 드래그 방향과 안 맞고, 검색은 개발 리소스 대비
//  우선순위가 낮다고 판단.
//

import CoreLocation
import SwiftUI

struct FieldCreationView: View {

    @Environment(\.dismiss) private var dismiss

    let editingField: Field?
    /// 등록을 취소해 이 플로우 전체를 닫아야 할 때 호출된다.
    var onFinish: () -> Void
    /// 등록을 마치고 "경기 준비" 화면(ReadyForMatchView)에서 "준비하기"를 눌렀을 때 호출된다.
    var onFieldPrepared: ((Field) -> Void)?
    /// 분석 기록처럼 경기 준비 단계 없이 새 경기장을 즉시 사용할 때 호출된다.
    var onFieldSaved: ((Field) -> Void)?
    /// 기존 경기장 수정 완료 시 편집 화면 전체를 닫도록 호출부에 알린다.
    var onFieldUpdated: ((Field) -> Void)?

    @State private var locationManager = CLLocationManager()
    @State private var goNext = false
    @State private var recenterTrigger = false

    /// 사용자가 찍은 원본 핀. 최대 4개. 찍은 순서는 FieldRectangleCorrector가 중앙값
    /// 기준으로 다시 매기므로 의미가 없다 — "몇 번째 핀을 찍었는지" 안내용으로만 쓴다.
    @State private var rawPinCoordinates: [CLLocationCoordinate2D]
    @State private var draggingIndex: Int?

    init(
        editingField: Field? = nil,
        onFinish: @escaping () -> Void = {},
        onFieldPrepared: ((Field) -> Void)? = nil,
        onFieldSaved: ((Field) -> Void)? = nil,
        onFieldUpdated: ((Field) -> Void)? = nil
    ) {
        self.editingField = editingField
        self.onFinish = onFinish
        self.onFieldPrepared = onFieldPrepared
        self.onFieldSaved = onFieldSaved
        self.onFieldUpdated = onFieldUpdated
        let coordinates = editingField.map(Self.editingCoordinates(for:)) ?? []
        _rawPinCoordinates = State(initialValue: coordinates)
    }

    private var guidanceText: String {
        switch rawPinCoordinates.count {
        case 0: return "운동장 꼭짓점을 탭해서 1번째 핀을 찍어주세요"
        case 1: return "2번째 핀을 찍어주세요"
        case 2: return "3번째 핀을 찍어주세요"
        case 3: return "4번째 핀을 찍어주세요"
        default: return "핀을 눌러서 드래그하면 위치를 조정할 수 있어요"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NaverMapView(
                pins: $rawPinCoordinates,
                draggingIndex: $draggingIndex,
                onTapEmptyMap: { coordinate in
                    guard rawPinCoordinates.count < 4 else { return }
                    rawPinCoordinates.append(coordinate)
                },
                recenterTrigger: recenterTrigger
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

            CtaView(
                text: editingField == nil ? "추가" : "다음",
                type: .primary,
                size: .large,
                isActive: rawPinCoordinates.count == 4
            ) {
                goNext = rawPinCoordinates.count == 4
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle(editingField == nil ? "경기장 등록" : "경기장 수정")
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
            FieldNamingView(
                rawCoordinates: rawPinCoordinates,
                editingField: editingField,
                onFinish: onFinish,
                onFieldPrepared: onFieldPrepared,
                onFieldSaved: onFieldSaved,
                onFieldUpdated: onFieldUpdated
            )
        }
    }

    private static func editingCoordinates(for field: Field) -> [CLLocationCoordinate2D] {
        let rawCorners = [field.rawCornerA, field.rawCornerB, field.rawCornerC, field.rawCornerD]
        let corners: [FieldCorner]
        if rawCorners.allSatisfy({ $0 != nil }) {
            corners = rawCorners.compactMap { $0 }
        } else {
            corners = [field.cornerA, field.cornerB, field.cornerC, field.cornerD]
        }
        return corners.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
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
            recenterTrigger.toggle()
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
