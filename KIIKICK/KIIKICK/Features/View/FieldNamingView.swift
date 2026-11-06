//
//  FieldNamingView.swift
//  KIIKICK
//
//  Figma node 256:1094 "newfield_03"(경기장 이름 입력) / 259:1467 "Alert"(등록 취소 확인) — iOS 화면
//
//  DESIGN-GAP: "selected field" 썸네일(256:1132)은 배경 이미지를 많이 확대/크롭해서
//  쓰는데, 정확한 확대/크롭 비율이 Figma 목업에만 있고 디자인 토큰으로 노출되어 있지
//  않아 재현하지 않았다. 대신 같은 자산(img_field)을 썸네일 전체에 채우는 것으로
//  근사했다.
//

import CoreLocation
import SwiftData
import SwiftUI

struct FieldNamingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let coordinates: [CLLocationCoordinate2D]
    var onFinish: () -> Void = {}

    @State private var fieldName: String = ""
    @State private var isPresentingLeaveConfirm = false

    private var canSave: Bool {
        !fieldName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 28) {
            thumbnail

            KiikickTextField(
                text: $fieldName,
                placeholder: "경기장 이름을 지어주세요",
                state: fieldName.isEmpty ? .default : .completed,
                maxCount: 18
            )

            Spacer()

            CtaView(text: "등록 완료", type: .primary, size: .large, isActive: canSave) {
                save()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("경기장 등록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { handleBack() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .alert("경기장 등록을 취소할까요?", isPresented: $isPresentingLeaveConfirm) {
            Button("계속 등록", role: .cancel) {}
            Button("등록 취소", role: .destructive) { onFinish() }
        } message: {
            Text("입력한 내용은 저장되지 않아요.")
        }
    }

    private var thumbnail: some View {
        ZStack {
            Image("img_field")
                .resizable()
                .aspectRatio(contentMode: .fill)

            HStack(spacing: 8) {
                Image(systemName: "soccerball")
                    .font(.system(size: 20))
                    .foregroundStyle(.mint500)
                    .padding(6)
                    .background(Color.gray950, in: Circle())
                    .overlay(Circle().stroke(Color.mint500, lineWidth: 1))
                Text("축구장")
                    .font(.title4SB)
                    .foregroundStyle(.gray50)
            }
        }
        .frame(height: 138)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(24)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
    }

    private func handleBack() {
        if canSave {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard coordinates.count == 4 else { return }
        let field = Field(
            name: fieldName,
            cornerA: FieldCorner(latitude: coordinates[0].latitude, longitude: coordinates[0].longitude),
            cornerB: FieldCorner(latitude: coordinates[1].latitude, longitude: coordinates[1].longitude),
            cornerC: FieldCorner(latitude: coordinates[2].latitude, longitude: coordinates[2].longitude),
            cornerD: FieldCorner(latitude: coordinates[3].latitude, longitude: coordinates[3].longitude)
        )
        modelContext.insert(field)
        try? modelContext.save()
        onFinish()
    }
}

#Preview {
    NavigationStack {
        FieldNamingView(coordinates: [
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.0),
        ])
    }
}
