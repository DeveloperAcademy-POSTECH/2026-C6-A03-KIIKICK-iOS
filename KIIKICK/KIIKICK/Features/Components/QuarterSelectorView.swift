//
//  QuarterSelectorView.swift
//  KIIKICK
//
//  Figma "QuaterSelector" (node 519:5512, "분석 상세" 화면 상단) — AnalysisDetailView에
//  private quarterPager로 인라인돼 있던 걸 공용 컴포넌트로 뺐다. ic/triangle_l·r
//  24×24, 가운데 "N 쿼터" title2_sb(18pt) + "mm:ss" body3_r(14pt), 양옆 간격 64.
//

import SwiftUI

struct QuarterSelectorView: View {
    let quarterNumber: Int
    let durationText: String
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image("ic_triangle_l")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(canGoPrevious ? .colorTextPrimary : .gray700)
            }
            .buttonStyle(.plain)
            .disabled(!canGoPrevious)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("\(quarterNumber) 쿼터")
                    .lineLimit(1)
                    .font(.title2SB)
                Text(durationText)
                    .font(.body3R)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.colorTextPrimary)
            
            Spacer()
            
            Button(action: onNext) {
                Image("ic_triangle_r")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(canGoNext ? .colorTextPrimary : .gray700)
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)
        }
        .frame(width: 220)
    }
}

#Preview {
    QuarterSelectorView(
        quarterNumber: 1, durationText: "26:03",
        canGoPrevious: false, canGoNext: true,
        onPrevious: {}, onNext: {}
    )
    .padding()
    .background(Color.gray950)
}
