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
//  바깥 VStack을 width: 100으로 고정해뒀던 게 "00"/두 자리 점수 기준이었다 — 100점
//  (Overdrive 경계)처럼 세 자리가 되면 display0SB(64pt Kanit) 글자가 100pt보다
//  넓어져서 줄바꿈되고, 고정 height 때문에 "1…"로 잘렸다. 공유 카드(ShareCardView)의
//  "km/h" 잘림과 같은 원인 — 점수 Text에 .fixedSize()를 주고 바깥 폭 고정을 없애서
//  항상 한 줄 그대로 그리게 했다.
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
                .fixedSize()
                .frame(height: 64 * 1.2) // Figma가 쓰는 120% line-height 기준 = 76.8pt
                .foregroundStyle(.colorTextPrimary)
            if let delta {
                Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                    .font(.label3M)
                    .foregroundStyle(delta >= 0 ? .feedbackInfo : .feedbackError)
                    .fixedSize()
                    .frame(minWidth: 40)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(minWidth: 100, minHeight: delta == nil ? 106 : 136)
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
