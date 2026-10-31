//
//  MyPageView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/29/26.
//

import SwiftUI

struct MyPageView: View {
    @Environment(AppRouter.self) private var router

    @State private var nickname: String = UserSession.nickname ?? ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var isPresentingDeleteConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            Text("마이페이지")
                .font(.title2)
                .fontWeight(.bold)

            TextField("닉네임", text: $nickname)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("닉네임 저장") {
                Task { await updateNickname() }
            }
            .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            .buttonStyle(.borderedProminent)

            Button("회원 탈퇴", role: .destructive) {
                isPresentingDeleteConfirm = true
            }
            .disabled(isSubmitting)
        }
        .padding()
        .confirmationDialog("정말 탈퇴하시겠어요?", isPresented: $isPresentingDeleteConfirm, titleVisibility: .visible) {
            Button("탈퇴", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func updateNickname() async {
        guard let userId = UserSession.userId else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let user = try await UserAPI.update(userId: userId, nickname: nickname)
            UserSession.nickname = user.nickname
        } catch let APIError.serverError(_, message) {
            errorMessage = message ?? "닉네임 수정에 실패했습니다. 다시 시도해주세요."
        } catch {
            errorMessage = "닉네임 수정에 실패했습니다. 다시 시도해주세요."
        }
    }

    private func deleteAccount() async {
        guard let userId = UserSession.userId else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await UserAPI.delete(userId: userId)
            UserSession.clear()
            router.didSignOut()
        } catch {
            errorMessage = "탈퇴에 실패했습니다. 다시 시도해주세요."
        }
    }
}

#Preview {
    MyPageView()
        .environment(AppRouter())
}
