//
//  SignUpView.swift
//  KIIKICK
//

import SwiftUI

struct SignUpView: View {
    @Environment(AppRouter.self) private var router

    @State private var nickname: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("닉네임을 입력해주세요")
                .font(.title2)
                .fontWeight(.bold)

            TextField("닉네임", text: $nickname)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("시작하기") {
                Task { await submit() }
            }
            .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("회원가입")
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let user = try await UserAPI.create(nickname: nickname)
            UserSession.save(userId: user.id, nickname: user.nickname)
            router.didLogIn()
        } catch let APIError.serverError(_, message) {
            errorMessage = message ?? "회원가입에 실패했습니다. 다시 시도해주세요."
        } catch {
            errorMessage = "회원가입에 실패했습니다. 다시 시도해주세요."
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(AppRouter())
    }
}
