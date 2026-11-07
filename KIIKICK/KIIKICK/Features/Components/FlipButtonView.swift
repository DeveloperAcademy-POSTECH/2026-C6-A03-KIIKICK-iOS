//
//  FlipButtonView.swift
//  KIIKICK
//
//  Figma "btn_flip" (node 742:11815 "card_quarter" 안) — 히트맵 좌우반전 토글 버튼.
//  bg color-surface-elevated(gray800), 높이 40, radius-full(999), ic/flip + "좌우반전"
//  label4_sb(12pt). 눌린 상태(반전됨)를 표시하는 별도 Figma variant는 없어서, 반전
//  중일 땐 아이콘/텍스트를 mint500으로 바꿔 상태를 구분했다 — DESIGN-GAP.
//

import SwiftUI

struct FlipButtonView: View {
    @Binding var isFlipped: Bool

    var body: some View {
        Button {
            isFlipped.toggle()
        } label: {
            HStack(spacing: 4) {
                Image("ic_flip")
                    .resizable()
                    .frame(width: 22, height: 21)
                Text("좌우반전")
                    .font(.label4SB)
            }
            .foregroundStyle(isFlipped ? .mint500 : .colorTextPrimary)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color.gray800, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        FlipButtonView(isFlipped: .constant(false))
        FlipButtonView(isFlipped: .constant(true))
    }
    .padding()
    .background(Color.gray950)
}
