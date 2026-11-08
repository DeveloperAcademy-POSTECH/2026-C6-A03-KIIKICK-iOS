//
//  PositionDropdownView.swift
//  KIIKICK
//
//  Figma node 519:6007 "dropdown_position" (Assets&Components 페이지) — 포지션 10개를
//  3열 그리드로 펼쳐서 고르는 드롭다운. 그리드 칩은 기존 "chip" 컴포넌트(FilterChipView)를
//  그대로 재사용한다.
//

import SwiftUI

struct PositionDropdownView: View {
    static let rows: [[String?]] = [
        ["LW", "ST", "RW"],
        ["LM", "CM", "RM"],
        ["LB", "CB", "RB"],
        [nil, "GK", nil],
    ]

    @Binding var position: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(position)
                        .font(.body4R)
                        .foregroundStyle(.gray50)
                    Image("ic_chevron_down")
                        .resizable()
                        .foregroundStyle(.gray50)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
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
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 4) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, item in
                                if let item {
                                    Button {
                                        position = item
                                        withAnimation(.easeInOut) { isExpanded = false }
                                    } label: {
                                        FilterChipView(text: item, isSelected: item == position)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color.gray800, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    PositionDropdownView(position: .constant("CM"))
        .padding()
        .background(Color.gray950)
}
