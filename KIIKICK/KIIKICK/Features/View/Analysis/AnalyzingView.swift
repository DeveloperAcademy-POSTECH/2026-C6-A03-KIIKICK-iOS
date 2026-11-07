//
//  AnalyzingView.swift
//  KIIKICK
//
//  Figma node 585:6808 "analyzing" (이슈 #43) — 경기 분석 중 보여주는 로딩 화면.
//  "JSON 파일 재생은 Lottie로 재생" 요구사항대로 LottieView(Components/LottieView.swift)
//  + KIIKICK Global/Animations/analyzing.json을 쓴다.
//
//  분석 플로우: ReadyForDetailView → 여기 → AnalysisDetailView. 실제 분석 API가 없어서
//  "API 응답을 기다리는 중"을 Task.sleep으로 흉내 내고, 끝나면 바로 AnalysisDetailView로
//  넘어간다 — 플로우 확인용 목업이라 ReadyForDetailView에서 바꾼 포지션/반전 값은 반영하지
//  않는다(AnalysisDetail은 여전히 AnalysisMockData 원본을 그대로 보여준다).
//

import SwiftUI

struct AnalyzingView: View {
    let entry: AnalysisEntry

    @State private var isComplete = false

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
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            isComplete = true
        }
        .navigationDestination(isPresented: $isComplete) {
            AnalysisDetailView(entry: entry)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyzingView(entry: AnalysisMockData.entries[0])
    }
}
