// Figma 575:9884 / 575:9916의 기존 사진 설정·환영 화면을 재사용한다.
import SwiftUI
import PhotosUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let registrationToken: String?
    let password: String?
    let nickname: String

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: Image?
    @State private var completion = SignUpCompletionModel()
    @State private var isLoadingPhoto = false
    @State private var submissionRequested = false

    var body: some View {
        Group {
            if completion.isWelcoming {
                welcomeContent
            } else {
                formContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: completion.isWelcoming ? .center : .top)
        .background(Color.gray950)
        .task(id: selectedPhotoItem) { await loadSelectedPhoto() }
        .task(id: submissionRequested) {
            guard submissionRequested else { return }
            await completion.complete(registrationToken: registrationToken, password: password, nickname: nickname)
            submissionRequested = false
        }
    }

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingProgressBarView(currentStep: 4, totalSteps: 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("나를 보여줄\n사진을 설정해주세요")
                    .font(.head1B)
                    .foregroundStyle(.gray50)
                    .fixedSize(horizontal: false, vertical: true)
                Text("사진은 선택사항이에요")
                    .font(.body4R)
                    .foregroundStyle(.gray400)
            }

            VStack(spacing: 20) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        if let selectedPhoto {
                            selectedPhoto
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image("img_profile_default")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
                }
                .disabled(completion.isSubmitting || submissionRequested)
                .accessibilityLabel("프로필 사진 선택")

                VStack(spacing: 8) {
                    Text("사진 선택")
                        .font(.body4R)
                        .foregroundStyle(.mint500)
                    Text("마이페이지에서 언제든 변경할 수 있어요")
                        .font(.caption1M)
                        .foregroundStyle(.gray400)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // DESIGN-GAP: API 오류·진행 상태의 별도 시안은 미확인. 기존 오류 영역과 CTA 비활성을 재사용한다.
            if let errorMessage = completion.errorMessage {
                Text(errorMessage)
                    .font(.caption1M)
                    .foregroundStyle(.red500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            CtaView(text: "가입 완료", type: .primary, size: .large, isActive: !completion.isSubmitting && !submissionRequested && !isLoadingPhoto) {
                submissionRequested = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
                    .disabled(completion.isSubmitting || submissionRequested || completion.hasCreatedAccount)
                    .accessibilityLabel("이전 단계")
            }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 40) {
            ZStack {
                if let selectedPhoto {
                    selectedPhoto
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    CurrentUserAvatarView()
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(Circle())

            Text("환영합니다\n\(UserSession.nickname ?? nickname)!")
                .font(.head1B)
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await showHomeAfterWelcome() }
    }

    private func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        isLoadingPhoto = true
        selectedPhoto = nil
        completion.selectedPhotoData = nil
        completion.errorMessage = nil
        defer {
            if selectedPhotoItem == item { isLoadingPhoto = false }
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw AvatarImageError.invalidImage
            }
            try Task.checkCancellation()
            guard selectedPhotoItem == item else { return }
            let avatar = try AvatarImage(data: data)
            selectedPhoto = Image(uiImage: avatar.image)
            completion.selectedPhotoData = avatar.jpegData
        } catch {
            guard !Task.isCancelled, selectedPhotoItem == item else { return }
            completion.errorMessage = error.localizedDescription
        }
    }

    private func showHomeAfterWelcome() async {
        do {
            try await Task.sleep(for: .seconds(3))
            try Task.checkCancellation()
            router.didCompleteOnboarding()
        } catch is CancellationError {
            // 화면이 사라지면 예약된 홈 이동도 취소한다.
        } catch {
            completion.errorMessage = "홈으로 이동하지 못했어요. 다시 시도해 주세요"
        }
    }
}

#Preview {
    NavigationStack {
        SignUpProfileView(registrationToken: "preview-token", password: "preview-password1!", nickname: "효자동 조규성")
            .environment(AppRouter())
    }
}
