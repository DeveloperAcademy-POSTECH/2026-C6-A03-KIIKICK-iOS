//
//  OverallScoreView.swift
//  KIIKICK
//
//  Figma 컴포넌트 "OverallScore" (node 732:6852, variants "Property 1" = plus/minus).
//  get_design_context로 받은 값 그대로: "Overall" 라벨과 점수 둘 다 color-text-primary
//  (gray50)이고, 라벨은 title1_sb(20pt), 점수는 display0_sb(64pt, Kanit). 증감 배지는
//  고정 40pt 너비, color-surface-primary(gray850) 배경에 radius-sm(8), label3_m(14pt) —
//  양수는 feedback/info(lime500), 음수는 feedback/error(red500)로 색이 바뀐다.
//
//  이전에 get_variable_defs(733:9112)로 "Overall" 라벨이 label3_m+gray400(secondary)이라고
//  잘못 적었던 적이 있다 — 그건 그 프레임의 다른 텍스트 레이어 값이었다. 이 컴포넌트
//  node를 직접 읽은 지금 값(title1_sb + color-text-primary)이 맞다.
//

import SwiftUI

struct OverallScoreView: View {
    let score: Int?
    let delta: Int?

    var body: some View {
        VStack(spacing: 4) {
            Text("Overall")
                .font(.title1SB)
                .foregroundStyle(.colorTextPrimary)
            Text(score.map(String.init) ?? "00")
                .font(.display0SB)
                .frame(height: 64 * 1.2) // Figma가 쓰는 120% line-height 기준 = 76.8pt
                .foregroundStyle(.colorTextPrimary)
            if let delta {
                Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                    .font(.label3M)
                    .foregroundStyle(delta >= 0 ? .feedbackInfo : .feedbackError)
                    .frame(width: 40)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 100, height: delta == nil ? 106 : 136)
    }
}

#Preview("plus") {
    OverallScoreView(score: 90, delta: 2)
        .padding()
        .background(Color.gray950)
}

#Preview("minus") {
    OverallScoreView(score: 90, delta: -2)
        .padding()
        .background(Color.gray950)
}

#Preview("empty") {
    OverallScoreView(score: nil, delta: nil)
        .padding()
        .background(Color.gray950)
}
