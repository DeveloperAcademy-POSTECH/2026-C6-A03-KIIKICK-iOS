//
//  EmptyStateView.swift
//  KIIKICK
//
//  Figma "img_empty" 기반 빈 상태 패턴(예: node 541:3658 "analysis_empty") — 일러스트 +
//  두 줄 텍스트. 화면마다 문구만 다르고 레이아웃은 동일해서 공용 컴포넌트로 뺐다.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image("img_empty")
                .resizable()
                .frame(width: 200, height: 200)
            VStack(spacing: 0) {
                Text(title)
                Text(subtitle)
            }
            .font(.body4R)
            .foregroundStyle(.gray50)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(title: "아직 경기 기록이 없어요", subtitle: "경기를 완료하면 이곳에서 분석 결과를 볼 수 있어요")
        .padding()
        .background(Color.gray950)
}
