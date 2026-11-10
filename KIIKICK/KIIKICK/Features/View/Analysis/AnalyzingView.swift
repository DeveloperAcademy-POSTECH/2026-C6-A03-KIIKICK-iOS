//
//  AnalyzingView.swift
//  KIIKICK
//
//  Figma node 585:6808 "analyzing" (이슈 #43) — 경기 분석 중 보여주는 로딩 화면.
//  "JSON 파일 재생은 Lottie로 재생" 요구사항대로 LottieView(Components/LottieView.swift)
//  + KIIKICK Global/Animations/analyzing.json을 쓴다.
//
//  분석 플로우: ReadyForDetailView → 여기 → AnalysisDetailView. 실제 분석 API가 없어서
//  "API 응답을 기다리는 중"을 Task.sleep으로 흉내 낸다. 분석 준비에서 로컬에 저장한
//  포지션/공격 방향이 포함된 entry를 분석 상세에 그대로 전달한다.
//
//  분석이 끝나면 진입한 탭의 스택에서 ready+analyzing 두 단계를 지우고
//  detail만 새로 쌓는다 — 그래야 AnalysisDetailView에서 뒤로 갔을 때 이 로딩 화면이나
//  ReadyForDetailView로 돌아가지 않고 분석 목록 또는 알림 목록으로 돌아간다.
//

import SwiftUI

struct AnalyzingView: View {
    @Environment(AppRouter.self) private var router

    let entry: AnalysisEntry
    var navigationTab: AppRouter.AppTab = .analysis

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
            let expectedPathCount = router.paths[navigationTab]?.count
            do {
                try await Task.sleep(for: .seconds(1.5))
                try Task.checkCancellation()
                guard let expectedPathCount else { return }
                router.finishAnalysis(entry, in: navigationTab, expectedPathCount: expectedPathCount)
            } catch {
                // 화면이 사라지면 다른 탭이나 이전 스택으로 이동하지 않는다.
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AnalyzingView(entry: .previewSample)
    }
    .environment(AppRouter())
}
#endif
