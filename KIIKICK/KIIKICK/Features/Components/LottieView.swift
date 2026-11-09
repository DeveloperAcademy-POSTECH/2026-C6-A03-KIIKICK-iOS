//
//  LottieView.swift
//  KIIKICK
//
//  이슈 #43: "분석중" 화면(Figma node 585:6808 "analyzing")처럼 JSON 애니메이션을
//  재생해야 하는 화면에서 공통으로 쓰는 얇은 래퍼. Lottie 자체 SwiftUI API
//  (Lottie.LottieView)를 그대로 감싸서, 반복 재생 기본값만 이 프로젝트 기준으로
//  통일했다.
//
//  "KIIKICK Global/Animations/" 아래에 있는 .json 파일 이름을 그대로 넘긴다
//  (확장자 제외) — 예: "analyzing"(KIIKICK Global/Animations/analyzing.json, 이미 있음).
//  파일이 없으면 Lottie가 빈 화면을 그릴 뿐 크래시하지 않는다.
//

import SwiftUI
import Lottie

struct LottieView: View {
    let name: String
    var loopMode: LottieLoopMode = .loop

    var body: some View {
        Lottie.LottieView(animation: .named(name, bundle: .main))
            .playing(loopMode: loopMode)
            .resizable()
    }
}

#Preview {
    LottieView(name: "analyzing")
        .frame(width: 200, height: 200)
        .background(Color.gray950)
}
