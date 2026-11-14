//
//  FieldChangeRow.swift
//  KIIKICK
//
//  이슈 #96: 운동장 변경 진입점. 분석 준비(ReadyForDetailView)의 경기 단위·쿼터 단위,
//  분석 상세(AnalysisDetailView) 세 자리에서 같은 행을 쓴다.
//
//  DESIGN-GAP: Figma에 운동장 변경 행이 아직 없다 — 같은 화면의 "포지션" 행
//  (CardQuarterView, label1M 라벨 + 우측 컨트롤)과 같은 구성으로 맞췄다.
//

import SwiftUI

struct FieldChangeRow: View {
    let field: Field?
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("운동장")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text(field?.name ?? "미지정")
                .font(.body4R)
                .foregroundStyle(field == nil ? .colorTextSecondary : .colorTextPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(action: action) {
                HStack(spacing: 2) {
                    Text(field == nil ? "지정하기" : "변경")
                        .font(.caption1M)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.mint500)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(field == nil ? "운동장 지정하기" : "운동장 변경, 현재 \(field?.name ?? "")")
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        FieldChangeRow(field: nil) {}
        FieldChangeRow(field: Field(
            name: "포스텍 대운동장",
            cornerA: FieldCorner(latitude: 36.01, longitude: 129.32),
            cornerB: FieldCorner(latitude: 36.01, longitude: 129.33),
            cornerC: FieldCorner(latitude: 36.02, longitude: 129.33),
            cornerD: FieldCorner(latitude: 36.02, longitude: 129.32)
        )) {}
    }
    .padding()
    .background(Color.gray950)
}
#endif
