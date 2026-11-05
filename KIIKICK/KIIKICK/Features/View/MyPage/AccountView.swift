//
//  AccountView.swift
//  KIIKICK
//
//  Figma node 392:4529 "account", 394:2119 "Alert"(로그아웃), 394:2140 "Alert"(회원 탈퇴) — iOS 화면
//

import SwiftUI

struct AccountView: View {
    @Environment(AppRouter.self) private var router

    @State private var isSubmitting = false
    @State private var isPresentingLogoutConfirm = false
    @State private var isPresentingDeleteConfirm = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                isPresentingLogoutConfirm = true
            } label: {
                NaviRowView(text: "로그아웃", textStyle: .title3M, textColor: .gray50)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            Button {
                isPresentingDeleteConfirm = true
            } label: {
                NaviRowView(text: "회원 탈퇴", textStyle: .title3M, textColor: .red500)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            if let deleteErrorMessage {
                Text(deleteErrorMessage)
                    .font(.caption1M)
                    .foregroundStyle(.red500)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("계정 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("로그아웃할까요?", isPresented: $isPresentingLogoutConfirm) {
            Button("취소", role: .cancel) {}
            Button("로그아웃") { logOut() }
        } message: {
            Text("언제든지 다시 로그인할 수 있어요")
        }
        .alert("정말 탈퇴할까요?", isPresented: $isPresentingDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("회원 탈퇴", role: .destructive) { Task { await deleteAccount() } }
        } message: {
            Text("계정과 경기 기록이 삭제되며, 삭제된 정보는 복구할 수 없어요.")
        }
    }

    private func logOut() {
        UserSession.clear()
        router.didLogOut()
    }

    private func deleteAccount() async {
        guard let userId = UserSession.userId else { return }
        isSubmitting = true
        deleteErrorMessage = nil
        defer { isSubmitting = false }

        do {
            try await NetworkService.provider.requestWithoutResponse(with: UserEndpoints.delete(userId: userId))
            UserSession.clear()
            router.didSignOut()
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            deleteErrorMessage = message ?? "탈퇴하지 못했어요. 다시 시도해 주세요"
        } catch {
            deleteErrorMessage = "탈퇴하지 못했어요. 다시 시도해 주세요"
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
    .environment(AppRouter())
}
