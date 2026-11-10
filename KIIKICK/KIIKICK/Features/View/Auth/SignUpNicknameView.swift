//
//  SignUpNicknameView.swift
//  KIIKICK
//
//  Figma node 575:9812 "signup_03" (iOS 화면, 3/4단계) — 닉네임 설정
//
//  DESIGN-GAP: Figma에는 닉네임 중복 시 에러 상태("이미 사용 중인 닉네임이에요")도
//  있지만, 중복 여부를 확인하려면 서버 API가 필요하다(Auth API 변경 예정이라 연동
//  대상에서 제외 — 기존 닉네임 단독 가입 플로우의 #28과 같은 종류의 갭).
//  형식 검증(공백/길이/이모지)만 클라이언트에서 수행한다.
//

import SwiftUI

struct SignUpNicknameView: View {
    @Environment(\.dismiss) private var dismiss

    let registrationToken: String?
    let password: String?

    @State private var nickname: String = ""
    @State private var goNext = false

    private var validationError: String? {
        if nickname.isEmpty { return nil }
        if nickname.trimmingCharacters(in: .whitespaces).isEmpty {
            return "공백만으로는 닉네임을 설정할 수 없어요"
        }
        if nickname.containsEmoji {
            return "이모티콘은 사용할 수 없어요"
        }
        return nil
    }

    private var fieldState: KiikickTextFieldState {
        if nickname.isEmpty { return .default }
        return validationError == nil ? .completed : .error
    }

    private var canSubmit: Bool {
        !nickname.isEmpty && validationError == nil
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
            if registrationToken != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.backward") }
                }
            }
        }
        .navigationDestination(isPresented: $goNext) {
            SignUpProfileView(registrationToken: registrationToken, password: password, nickname: nickname)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingProgressBarView(currentStep: 3, totalSteps: 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("어떤 이름으로\n불러드릴까요?")
                    .font(.head1B)
                    .foregroundStyle(.gray50)
                    .fixedSize(horizontal: false, vertical: true)
                Text("친구들에게 보여줄 닉네임을 설정해주세요")
                    .font(.body4R)
                    .foregroundStyle(.gray400)
            }

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("닉네임")
                        .font(.label3M)
                        .foregroundStyle(.gray400)
                    KiikickTextField(
                        text: $nickname,
                        placeholder: "닉네임 입력",
                        state: fieldState,
                        errorMessage: validationError ?? "",
                        maxCount: 10
                    )
                }

                Text("닉네임은 마이페이지에서 변경할 수 있어요")
                    .font(.caption1M)
                    .foregroundStyle(.gray400)
                    .padding(.top, 20)
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

private extension String {
    var containsEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmoji && $0.properties.isEmojiPresentation }
    }
}

#Preview {
    NavigationStack {
        SignUpNicknameView(registrationToken: "preview-token", password: "preview-password1!")
            .environment(AppRouter())
    }
}
