//
//  SignUpEmailView.swift
//  KIIKICK
//
//  Figma node 575:9502 "signup_01" (iOS 화면, 1/4단계) — 이메일 입력 + 인증코드 확인
//
//  DESIGN-GAP: 이메일 인증 API가 아직 없어(Auth API 변경 예정), 인증코드는 실제로
//  발송/검증되지 않는다. 6자리 숫자를 모두 입력하면 바로 인증 성공으로 처리한다.
//

import SwiftUI

struct SignUpEmailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var code: String = ""
    @State private var isCodeSent = false
    @State private var isVerified = false
    @State private var goNext = false

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var emailFieldState: KiikickTextFieldState {
        if isCodeSent { return isEmailValid ? .completed : .default }
        if email.isEmpty { return .default }
        return isEmailValid ? .completed : .error
    }

    private var canSendCode: Bool {
        !isCodeSent && isEmailValid
    }

    private var canVerify: Bool {
        isCodeSent && !isVerified && code.count == 6
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.gray950
                .ignoresSafeArea()
                .dismissKeyboardOnTap()

            content
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .navigationDestination(isPresented: $goNext) {
            SignUpPasswordView()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingProgressBarView(currentStep: 1, totalSteps: 4)

            Text("이메일을\n입력해주세요")
                .font(.head1B)
                .foregroundStyle(.gray50)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일")
                        .font(.label3M)
                        .foregroundStyle(.gray400)
                    KiikickTextField(
                        text: $email,
                        placeholder: "kiikick@email.com",
                        state: emailFieldState,
                        errorMessage: "올바른 이메일 형식으로 입력해 주세요"
                    )
                    .disabled(isCodeSent)

                    if isCodeSent {
                        Button("이메일 변경") {
                            isCodeSent = false
                            isVerified = false
                            code = ""
                        }
                        .font(.caption1M)
                        .foregroundStyle(.mint500)
                    } else {
                        Text("입력한 이메일로 인증코드를 보내드려요")
                            .font(.caption1M)
                            .foregroundStyle(.gray400)
                    }
                }

                if isCodeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("인증코드")
                            .font(.label3M)
                            .foregroundStyle(.gray400)
                        KiikickTextField(
                            text: $code,
                            placeholder: "인증코드 입력",
                            state: isVerified ? .completed : .default,
                            maxCount: 6
                        )
                        .keyboardType(.numberPad)

                        Button("다시 보내기") {
                            code = ""
                            isVerified = false
                        }
                        .font(.caption1M)
                        .foregroundStyle(.mint500)
                    }
                }
            }

            Spacer()

            CtaView(
                text: isVerified ? "다음" : (isCodeSent ? "인증하기" : "인증코드 받기"),
                type: .primary,
                size: .large,
                isActive: isVerified || canSendCode || canVerify
            ) {
                if isVerified {
                    goNext = true
                } else if isCodeSent {
                    isVerified = true
                } else {
                    isCodeSent = true
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack {
        SignUpEmailView()
            .environment(AppRouter())
    }
}
