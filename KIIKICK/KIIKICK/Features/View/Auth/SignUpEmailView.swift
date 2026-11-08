//
//  SignUpEmailView.swift
//  KIIKICK
//
//  Figma node 575:9502 "signup_01" (iOS 화면, 1/4단계) — 이메일 입력 + 인증코드 확인
//
//  AuthEndpoints.requestEmailVerification/verifyEmailVerification을 호출한다.
//  인증에 성공하면 받은 registrationToken을 다음 단계(SignUpPasswordView)로 들고 간다 —
//  실제 회원가입(AuthEndpoints.signup)은 비밀번호까지 다 모은 맨 마지막 단계에서 호출된다.
//

import SwiftUI

struct SignUpEmailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var code: String = ""
    @State private var isCodeSent = false
    @State private var isVerified = false
    @State private var goNext = false
    @State private var isSubmitting = false
    @State private var sendErrorMessage: String?
    @State private var verifyErrorMessage: String?

    @State private var verificationId: UUID?
    @State private var registrationToken = ""

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var emailFieldState: KiikickTextFieldState {
        if sendErrorMessage != nil { return .error }
        if isCodeSent { return isEmailValid ? .completed : .default }
        if email.isEmpty { return .default }
        return isEmailValid ? .completed : .error
    }

    private var codeFieldState: KiikickTextFieldState {
        if verifyErrorMessage != nil { return .error }
        return isVerified ? .completed : .default
    }

    private var canSendCode: Bool {
        !isCodeSent && isEmailValid && !isSubmitting
    }

    private var canVerify: Bool {
        isCodeSent && !isVerified && code.count == 6 && !isSubmitting
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
            SignUpPasswordView(registrationToken: registrationToken)
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
                        errorMessage: sendErrorMessage ?? "올바른 이메일 형식으로 입력해 주세요"
                    )
                    .disabled(isCodeSent)
                    .onChange(of: email) { sendErrorMessage = nil }

                    if isCodeSent {
                        Button("이메일 변경") {
                            isCodeSent = false
                            isVerified = false
                            code = ""
                            verificationId = nil
                            verifyErrorMessage = nil
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
                            state: codeFieldState,
                            errorMessage: verifyErrorMessage ?? "",
                            maxCount: 6
                        )
                        .keyboardType(.numberPad)
                        .onChange(of: code) { verifyErrorMessage = nil }

                        Button("다시 보내기") {
                            Task { await sendCode() }
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
                    Task { await verifyCode() }
                } else {
                    Task { await sendCode() }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func sendCode() async {
        isSubmitting = true
        sendErrorMessage = nil
        defer { isSubmitting = false }
        do {
            let result = try await NetworkService.provider.request(with: AuthEndpoints.requestEmailVerification(email: email))
            verificationId = result.data.verificationId
            code = ""
            isVerified = false
            isCodeSent = true
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            sendErrorMessage = message ?? "인증코드를 보내지 못했어요. 다시 시도해 주세요"
        } catch {
            sendErrorMessage = "인증코드를 보내지 못했어요. 다시 시도해 주세요"
        }
    }

    private func verifyCode() async {
        guard let verificationId else { return }
        isSubmitting = true
        verifyErrorMessage = nil
        defer { isSubmitting = false }
        do {
            let result = try await NetworkService.provider.request(
                with: AuthEndpoints.verifyEmailVerification(verificationId: verificationId, code: code)
            )
            registrationToken = result.data.registrationToken
            isVerified = true
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            verifyErrorMessage = message ?? "인증코드가 올바르지 않아요"
        } catch {
            verifyErrorMessage = "인증코드가 올바르지 않아요"
        }
    }
}

#Preview {
    NavigationStack {
        SignUpEmailView()
            .environment(AppRouter())
    }
}
