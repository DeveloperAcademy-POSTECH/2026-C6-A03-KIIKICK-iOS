//
//  FilterChipView.swift
//  KIIKICK
//
//  Figma node 317:2506 "chips" / 309:2029-2030 "chip" (notification 화면, Assets&Components 페이지)
//

import SwiftUI

struct FilterChipView: View {
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(.label1M)
            .foregroundStyle(isSelected ? .mint500 : .gray50)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.gray850, in: Capsule())
            .overlay(
                Capsule().stroke(isSelected ? .mint500 : .gray700, lineWidth: 1)
            )
    }
}

#Preview {
    HStack(spacing: 8) {
        FilterChipView(text: "전체", isSelected: true)
        FilterChipView(text: "댓글")
        FilterChipView(text: "친구 신청")
    }
    .padding()
    .background(Color.gray950)
}
