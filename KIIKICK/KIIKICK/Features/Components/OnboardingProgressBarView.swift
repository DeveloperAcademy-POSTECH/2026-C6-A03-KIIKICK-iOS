//
//  OnboardingProgressBarView.swift
//  KIIKICK
//
//  Figma node 413:2215~2218 "ProgressBar" (signup_01~04 상단) — 4단계 회원가입 진행도 표시
//

import SwiftUI

struct OnboardingProgressBarView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(step <= currentStep ? Color.mint500 : Color.gray800)
                    .frame(height: 3)
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        OnboardingProgressBarView(currentStep: 1, totalSteps: 4)
        OnboardingProgressBarView(currentStep: 2, totalSteps: 4)
        OnboardingProgressBarView(currentStep: 3, totalSteps: 4)
        OnboardingProgressBarView(currentStep: 4, totalSteps: 4)
    }
    .padding()
    .background(Color.gray950)
}
