//
//  SignUpProfileView.swift
//  KIIKICK
//
//  Figma node 575:9884 "signup_04"(사진 설정, 4/4단계) / 575:9916 "signup_05"(환영 메시지) — iOS 화면
//
import SwiftUI
import PhotosUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let nickname: String

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: ProfilePhoto?
    @State private var avatarUrl: URL?
    @State private var isLoadingPhoto = false
    @State private var isSubmitting = false
    @State private var photoError: String?
    @State private var isWelcoming = false

    var body: some View {
        Group {
            if isWelcoming {
                welcomeContent
            } else {
                formContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isWelcoming ? .center : .top)
        .background(Color.gray950)
        .task(id: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            isLoadingPhoto = true
            do {
                let photo = try await ProfilePhoto.load(item)
                guard !Task.isCancelled else { return }
                selectedPhoto = photo
                photoError = nil
            } catch {
                guard !Task.isCancelled else { return }
                photoError = "선택한 사진을 불러오지 못했어요"
            }
            isLoadingPhoto = false
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
                    ProfilePhotoView(
                        url: avatarUrl,
                        size: 112,
                        preview: selectedPhoto.map { Image(uiImage: $0.image) }
                    )
                }
                .disabled(isSubmitting)

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

            if let message = photoError {
                Text(message)
                    .font(.caption1M)
                    .foregroundStyle(.red)

                if selectedPhoto != nil {
                    Button("사진 없이 계속") {
                        selectedPhotoItem = nil
                        selectedPhoto = nil
                        photoError = nil
                    }
                    .disabled(isSubmitting)
                }
            }

            CtaView(text: "가입 완료", type: .primary, size: .large, isActive: !isSubmitting && !isLoadingPhoto) {
                Task { await completeSignUp() }
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
                    .disabled(isSubmitting)
            }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 40) {
            ProfilePhotoView(
                url: avatarUrl,
                size: 112,
                preview: selectedPhoto.map { Image(uiImage: $0.image) }
            )

            Text("환영합니다\n\(nickname)!")
                .font(.head1B)
                .foregroundStyle(.gray50)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }

    private func completeSignUp() async {
        guard !isSubmitting, !isLoadingPhoto else { return }
        isSubmitting = true
        photoError = nil
        defer { isSubmitting = false }

        if let token = UserSession.accessToken {
            if let selectedPhoto {
                do {
                    let response = try await NetworkService.provider.request(with: ProfileEndpoints.uploadAvatar(selectedPhoto.jpeg, token: token))
                    avatarUrl = response.data.avatarUrl
                } catch {
                    photoError = "프로필 사진을 저장하지 못했어요. 다시 시도해 주세요"
                    return
                }
            }
        } else {
            // 실제 가입 API가 연결되기 전에는 사진을 선택 화면에서만 미리 본다.
            UserSession.saveToken(UUID().uuidString)
        }

        UserSession.nickname = nickname
        withAnimation { isWelcoming = true }
        try? await Task.sleep(for: .seconds(1.2))
        router.didLogIn()
    }
}

#Preview {
    NavigationStack {
        SignUpProfileView(nickname: "효자동 조규성")
            .environment(AppRouter())
    }
}
