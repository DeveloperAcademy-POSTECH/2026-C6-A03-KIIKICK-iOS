//
//  LoginView.swift
//  KIIKICK
//
//  Figma 이슈 #31에 첨부된 로그인 화면 스크린샷 기준 — 페이지(120:12) 안에 해당 노드가
//  따로 존재하지 않아(다른 signup_01~05와 달리 "login" 프레임이 없음) 이슈에 첨부된
//  이미지를 그대로의 소스로 삼아 구현했다.
//
//  DESIGN-GAP: 이메일/비밀번호 로그인 API가 아직 없어(Auth API 변경 예정), 두 필드가
//  비어있지 않으면 바로 로그인에 성공한 것으로 처리하고 mock 토큰만 Keychain에 저장한다.
//  UserId는 설정하지 않으므로, UserId를 요구하는 화면/기능은 이 mock 로그인 이후에도
//  동작하지 않는다.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var email: String = ""
    @State private var password: String = ""

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var emailFieldState: KiikickTextFieldState {
        if email.isEmpty { return .default }
        return isEmailValid ? .completed : .error
    }

    private var passwordFieldState: KiikickTextFieldState {
        password.isEmpty ? .default : .completed
    }

    private var canSubmit: Bool {
        isEmailValid && !password.isEmpty
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
                        isSecure: true
                    )
                }
            }

            Spacer()

            VStack(spacing: 8) {
                CtaView(text: "로그인", type: .primary, size: .large, isActive: canSubmit) {
                    logIn()
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

    private func logIn() {
        UserSession.saveToken(UUID().uuidString)
        router.didLogIn()
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environment(AppRouter())
    }
}
