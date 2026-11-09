//
//  AnalyzingView.swift
//  KIIKICK
//
//  Figma node 585:6808 "analyzing" (이슈 #43) — 경기 분석 중 보여주는 로딩 화면.
//  "JSON 파일 재생은 Lottie로 재생" 요구사항대로 LottieView(Components/LottieView.swift)
//  + KIIKICK Global/Animations/analyzing.json을 쓴다.
//
//  분석 플로우: ReadyForDetailView → 여기 → AnalysisDetailView. 실제 분석 API가 없어서
//  "API 응답을 기다리는 중"을 Task.sleep으로 흉내 낸다 — 저장 API 연동은 범위 밖이라
//  ReadyForDetailView에서 바꾼 포지션/반전 값은 반영하지 않는다(AnalysisDetailView는
//  WorkoutRecord에서 빌드된 entry를 그대로 보여준다).
//
//  분석이 끝나면 router.paths[.analysis]에서 ready+analyzing 두 단계를 지우고
//  detail만 새로 쌓는다 — 그래야 AnalysisDetailView에서 뒤로 갔을 때 이 로딩 화면이나
//  ReadyForDetailView로 돌아가지 않고 바로 AnalysisView(목록)로 돌아간다.
//

import SwiftUI

struct AnalyzingView: View {
    @Environment(AppRouter.self) private var router

    let entry: AnalysisEntry

    var body: some View {
        VStack(spacing: 32) {
            Text("경기를 분석 중이에요")
                .font(.head3B)
                .foregroundStyle(.colorTextPrimary)

            // analyzing.json의 원본 캔버스는 402×312(공이 거의 전체 폭을 가로질러
            // 튀어다니는 애니메이션)이라, 정사각형 프레임으로 찌그러뜨리지 않게
            // 같은 비율(402:312)을 유지해서 키운다.
            LottieView(name: "analyzing")
                .frame(width: 300, height: 300 * 312 / 402)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            router.paths[.analysis]?.removeLast(2)
            router.paths[.analysis, default: .init()].append(AnalysisRoute.detail(entry))
        }
    }
}

#Preview {
    NavigationStack {
        AnalyzingView(entry: .previewSample)
    }
    .environment(AppRouter())
}
