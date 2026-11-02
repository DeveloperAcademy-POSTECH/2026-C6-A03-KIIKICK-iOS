//
//  CardInfoView.swift
//  KIIKICK
//
//  Figma node 259:2992 근처 "card_info" 컴포넌트. radius/padding/테두리 두께는
//  이번 세션에 정밀 재검증하지 못해 유사 컴포넌트 값으로 가정했다 — DESIGN-GAP.
//

import SwiftUI

struct CardInfoView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .textStyle(.title1SB)
                .foregroundStyle(.colorTextPrimary)
            Text(message)
                .textStyle(.body4R)
                .foregroundStyle(.colorTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        // DESIGN-GAP: radius 16 / border 1pt는 다른 카드 컴포넌트 유추값.
        .background(.colorBackgroundPrimary, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.brandPrimary, lineWidth: 1)
        }
    }
}

#Preview {
    CardInfoView(title: "우리 집 앞 풋살장", message: "경기가 준비되었어요. Apple Watch에서 시작해주세요")
        .padding()
        .background(Color.gray950)
}
