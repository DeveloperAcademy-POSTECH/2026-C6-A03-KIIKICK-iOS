//
//  AnalyzingView.swift
//  KIIKICK
//
//  Figma node 585:6808 "analyzing" (이슈 #43) — 경기 분석 중 보여주는 로딩 화면.
//  "JSON 파일 재생은 Lottie로 재생" 요구사항대로 LottieView(Components/LottieView.swift)
//  + KIIKICK Global/Animations/analyzing.json을 쓴다.
//
//  DESIGN-GAP: 분석 완료 시점(언제 다음 화면으로 넘어가는지)이나 그 다음 화면이 어디인지
//  아직 정해지지 않았다 — ReadyForDetailView와 마찬가지로 전체 플로우 연결은 범위 밖.
//

import SwiftUI

struct AnalyzingView: View {
    var body: some View {
        VStack(spacing: 32) {
            Text("경기를 분석 중이에요")
                .font(.head3B)
                .foregroundStyle(.colorTextPrimary)

            LottieView(name: "analyzing")
                .frame(width: 60, height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    AnalyzingView()
}
