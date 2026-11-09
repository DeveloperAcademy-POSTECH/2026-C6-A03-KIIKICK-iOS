//
//  LoginView.swift
//  KIIKICK
//
//  Figma 이슈 #31에 첨부된 로그인 화면 스크린샷 기준 — 페이지(120:12) 안에 해당 노드가
//  따로 존재하지 않아(다른 signup_01~05와 달리 "login" 프레임이 없음) 이슈에 첨부된
//  이미지를 그대로의 소스로 삼아 구현했다.
//
//  AuthEndpoints.login을 호출해 실제 세션(accessToken/refreshToken/sessionId)을
//  UserSession에 저장한다.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSubmitting = false
    @State private var loginErrorMessage: String?

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var emailFieldState: KiikickTextFieldState {
        if email.isEmpty { return .default }
        return isEmailValid ? .completed : .error
    }

    private var passwordFieldState: KiikickTextFieldState {
        if loginErrorMessage != nil { return .error }
        return password.isEmpty ? .default : .completed
    }

    private var canSubmit: Bool {
        isEmailValid && !password.isEmpty && !isSubmitting
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.gray950
                .ignoresSafeArea()
                .dismissKeyboardOnTap()

            content
        }
        .navigationTitle("로그인")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("이메일과 비밀번호를\n입력해주세요")
                .font(.head1B)
                .foregroundStyle(.gray50)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 20) {
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
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호")
                        .font(.label3M)
                        .foregroundStyle(.gray400)
                    KiikickTextField(
                        text: $password,
                        placeholder: "비밀번호 입력",
                        state: passwordFieldState,
                        errorMessage: loginErrorMessage ?? "",
                        isSecure: true
                    )
                    .onChange(of: password) { loginErrorMessage = nil }
                }
            }

            Spacer()

            VStack(spacing: 8) {
                CtaView(text: "로그인", type: .primary, size: .large, isActive: canSubmit) {
                    Task { await logIn() }
                }

                HStack(spacing: 4) {
                    Text("계정이 없으신가요?")
                        .foregroundStyle(.gray400)
                    NavigationLink("회원가입") {
                        SignUpEmailView()
                    }
                    .foregroundStyle(.mint500)
                }
                .font(.caption1M)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func logIn() async {
        isSubmitting = true
        loginErrorMessage = nil
        defer { isSubmitting = false }
        do {
            let result = try await NetworkService.provider.request(with: AuthEndpoints.login(email: email, password: password))
            UserSession.save(session: result.data)
            router.didLogIn()
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            loginErrorMessage = message ?? "로그인에 실패했어요. 다시 시도해 주세요"
        } catch {
            loginErrorMessage = "로그인에 실패했어요. 다시 시도해 주세요"
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AppRouter())
    }
}
