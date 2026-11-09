//
//  PositionDropdownView.swift
//  KIIKICK
//
//  Figma "dropdown_position" (node 742:11815 "card_quarter" 안에서 발견) — 포지션 선택
//  드롭다운 트리거. bg color-surface-elevated(gray800), border 1pt color-border-default
//  (gray700), radius-sm(8). 실제 드롭다운 목록 UI는 Figma에 없어 Menu로 구현했다.
//
//  DESIGN-GAP: Figma는 "ic/arrow-down" 에셋을 쓰는데 프로젝트엔 그 이름의 에셋이 없어
//  기존 ic_chevron_down으로 대체했다.
//

import SwiftUI

struct PositionDropdownView: View {
    @Binding var position: String
    // 하드코딩된 목록이 Position enum(공용, lw/st/rw/lm/cm/rm/lb/cb/rb/gk)과 따로
    // 있다가 LM/RM이 빠져 있었다 — enum을 그대로 소스로 써서 다시 벌어지지 않게 한다.
    var options: [String] = Position.allCases.map(\.uppercased)

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { position = option }
            }
        } label: {
            HStack(spacing: 8) {
                Text(position)
                    .font(.body4R)
                    .foregroundStyle(.colorTextPrimary)
                Image("ic_chevron_down")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.colorTextPrimary)
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .background(Color.gray800, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray700, lineWidth: 1)
            )
        }
    }
}

#Preview {
    PositionDropdownView(position: .constant("CM"))
        .padding()
        .background(Color.gray950)
}
