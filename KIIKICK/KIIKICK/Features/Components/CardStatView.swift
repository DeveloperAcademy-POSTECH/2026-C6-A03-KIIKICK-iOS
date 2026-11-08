//
//  CardStatView.swift
//  KIIKICK
//
//  Figma 컴포넌트 "card_stat" (node 732:6866). get_design_context로 받은 값 그대로:
//  108×108 고정 정사각형, background color-background-primary(gray950), border 1pt
//  color-border-default(gray700), radius-lg(16). 라벨은 caption2_sb(10pt)+
//  color-text-primary(gray50), 값은 display2_sb(32pt, Kanit)+gray50, 단위는
//  label3_m(14pt)+color-text-secondary(gray400).
//

import SwiftUI

struct CardStatView: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2SB)
                .foregroundStyle(.colorTextPrimary)
            VStack(spacing: 0) {
                Text(value)
                    .font(.display2SB)
                    .foregroundStyle(.colorTextPrimary)
                Text(unit)
                    .font(.label3M)
                    .foregroundStyle(.colorTextSecondary)
            }
        }
        .padding(.horizontal, 17)
        .frame(width: 108, height: 108)
        .background(Color.colorBackgroundPrimary, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray700, lineWidth: 1)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        CardStatView(label: "총 경기 수", value: "4", unit: "회")
        CardStatView(label: "총 이동거리", value: "12.4", unit: "km")
        CardStatView(label: "평균 소모 칼로리", value: "420", unit: "kcal")
    }
    .padding()
    .background(Color.gray950)
}
