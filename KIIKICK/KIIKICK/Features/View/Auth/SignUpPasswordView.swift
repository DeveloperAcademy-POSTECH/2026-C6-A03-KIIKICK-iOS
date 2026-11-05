//
//  SignUpPasswordView.swift
//  KIIKICK
//
//  Figma node 575:9724 "signup_02" (iOS 화면, 2/4단계) — 비밀번호 설정 + 확인
//
//  DESIGN-GAP: 비밀번호를 서버에 저장하는 API가 아직 없어(Auth API 변경 예정),
//  복잡도 검사는 전부 클라이언트에서만 이뤄지고 실제로 어디에도 전송되지 않는다.
//

import SwiftUI

struct SignUpPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var goNext = false

    private var passwordError: String? {
        guard !password.isEmpty else { return nil }
        if password.count < 10 {
            return "비밀번호는 최소 10자 이상이어야 해요"
        }
        let hasLetter = password.contains { $0.isLetter }
        let hasDigit = password.contains { $0.isNumber }
        let hasSpecial = password.contains { !$0.isLetter && !$0.isNumber }
        if !(hasLetter && hasDigit && hasSpecial) {
            return "영문, 숫자, 특수문자를 각각 1개 이상 포함해 주세요"
        }
        return nil
    }

    private var isPasswordValid: Bool {
        !password.isEmpty && passwordError == nil
    }

    private var passwordFieldState: KiikickTextFieldState {
        if password.isEmpty { return .default }
        return isPasswordValid ? .completed : .error
    }

    private var confirmError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return confirmPassword == password ? nil : "비밀번호가 일치하지 않아요"
    }

    private var confirmFieldState: KiikickTextFieldState {
        if confirmPassword.isEmpty { return .default }
        return confirmError == nil ? .completed : .error
    }

    private var canSubmit: Bool {
        isPasswordValid && !confirmPassword.isEmpty && confirmError == nil
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
            SignUpNicknameView()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 28) {
            OnboardingProgressBarView(currentStep: 2, totalSteps: 4)

            Text(isPasswordValid ? "비밀번호를\n한 번 더 입력해주세요" : "비밀번호를\n설정해주세요")
                .font(.head1B)
                .foregroundStyle(.gray50)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호")
                        .font(.label3M)
                        .foregroundStyle(.gray400)
                    KiikickTextField(
                        text: $password,
                        placeholder: "비밀번호 입력",
                        state: passwordFieldState,
                        errorMessage: passwordError ?? "",
                        maxCount: 16,
                        isSecure: true
                    )
                    .onChange(of: password) { confirmPassword = "" }
                }

                if isPasswordValid {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호 확인")
                            .font(.label3M)
                            .foregroundStyle(.gray400)
                        KiikickTextField(
                            text: $confirmPassword,
                            placeholder: "비밀번호 입력",
                            state: confirmFieldState,
                            errorMessage: confirmError ?? "",
                            maxCount: 16,
                            isSecure: true
                        )
                    }
                }
            }

            Spacer()

            CtaView(text: "다음", type: .primary, size: .large, isActive: canSubmit) {
                goNext = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NavigationStack {
        SignUpPasswordView()
            .environment(AppRouter())
    }
}
