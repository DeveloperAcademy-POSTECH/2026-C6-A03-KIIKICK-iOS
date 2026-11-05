//
//  QuarterSelectorView.swift
//  KIIKICK
//
//  Figma node 519:5514 "quaterSelector" (State=전체/중간/마지막/단일, Assets&Components 페이지)
//
//  DESIGN-GAP: Figma는 state별로 좌/우 삼각형 아이콘의 밝기가 다른 변형 asset을 따로
//  쓰지만(경계에서 더 이동할 수 없음을 표현), 여기서는 같은 아이콘에 opacity만 낮춰서
//  동일한 의미(비활성)를 표현한다.
//

import SwiftUI

struct QuarterSelectorView: View {
    let label: String
    let duration: String
    var canGoPrevious: Bool = true
    var canGoNext: Bool = true
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}

    var body: some View {
        HStack(spacing: 64) {
            Button(action: onPrevious) {
                Image("ic_triangle_l")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .opacity(canGoPrevious ? 1 : 0.3)
            }
            .buttonStyle(.plain)
            .disabled(!canGoPrevious)

            VStack(spacing: 8) {
                Text(label)
                    .font(.title2SB)
                    .foregroundStyle(.gray50)
                Text(duration)
                    .font(.body4R)
                    .foregroundStyle(.gray50)
            }
            .frame(width: 44)

            Button(action: onNext) {
                Image("ic_triangle_r")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .opacity(canGoNext ? 1 : 0.3)
            }
            .buttonStyle(.plain)
            .disabled(!canGoNext)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        QuarterSelectorView(label: "전체", duration: "26:03", canGoPrevious: false)
        QuarterSelectorView(label: "1 쿼터", duration: "26:03")
        QuarterSelectorView(label: "00 쿼터", duration: "26:03", canGoNext: false)
    }
    .padding()
    .background(Color.gray950)
}
