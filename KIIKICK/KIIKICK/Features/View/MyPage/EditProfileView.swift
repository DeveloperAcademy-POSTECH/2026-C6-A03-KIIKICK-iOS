//
//  EditProfileView.swift
//  KIIKICK
//
//  Figma node 392:4477 "editProfile", 392:4629 "Alert"(나가기 확인) — iOS 화면
//
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String
    @State private var isSubmitting = false
    @State private var saveErrorMessage: String?
    @State private var isPresentingLeaveConfirm = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: ProfilePhoto?
    @State private var avatarUrl: URL?
    @State private var shouldRemovePhoto = false
    @State private var isLoadingPhoto = false

    @State private var originalNickname: String

    init() {
        let current = UserSession.nickname ?? ""
        _nickname = State(initialValue: current)
        _originalNickname = State(initialValue: current)
    }

    private var hasUnsavedChanges: Bool {
        nickname != originalNickname || selectedPhoto != nil || shouldRemovePhoto
    }

    private var validationError: String? {
        if nickname.trimmingCharacters(in: .whitespaces).isEmpty {
            return "공백만으로는 닉네임을 설정할 수 없어요"
        }
        if nickname.count > 10 {
            return "닉네임은 공백 포함 10자 이내로 입력해주세요"
        }
        if nickname.containsEmoji {
            return "이모티콘은 사용할 수 없어요"
        }
        return nil
    }

    private var fieldState: KiikickTextFieldState {
        if saveErrorMessage != nil { return .error }
        if nickname.isEmpty { return .default }
        return validationError == nil ? .completed : .error
    }

    private var displayedError: String? {
        saveErrorMessage ?? validationError
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ProfilePhotoView(
                        url: shouldRemovePhoto ? nil : avatarUrl,
                        size: 99,
                        preview: selectedPhoto.map { Image(uiImage: $0.image) }
                    )
                }
                .disabled(isSubmitting || UserSession.accessToken == nil)

                Text("프로필 사진 변경")
                    .font(.caption1M)
                    .foregroundStyle(.mint500)

                if selectedPhoto != nil || (avatarUrl != nil && !shouldRemovePhoto) {
                    Button("사진 제거", role: .destructive) {
                        selectedPhotoItem = nil
                        selectedPhoto = nil
                        isLoadingPhoto = false
                        shouldRemovePhoto = avatarUrl != nil
                    }
                    .font(.caption1M)
                    .disabled(isSubmitting)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                Text("닉네임")
                    .font(.body4R)
                    .foregroundStyle(.gray400)
                KiikickTextField(
                    text: $nickname,
                    state: fieldState,
                    errorMessage: displayedError ?? ""
                )
                .disabled(isSubmitting)
                .onChange(of: nickname) { saveErrorMessage = nil }
            }

            Spacer()

            CtaView(text: "저장", type: .primary, isActive: hasUnsavedChanges && validationError == nil && !isSubmitting && !isLoadingPhoto) {
                Task { await save() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleBack()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .disabled(isSubmitting)
            }
        }
        .alert("프로필 수정을 그만둘까요?", isPresented: $isPresentingLeaveConfirm) {
            Button("계속 수정", role: .cancel) {}
            Button("나가기", role: .destructive) { dismiss() }
        } message: {
            Text("변경한 내용은 저장되지 않아요.")
        }
        .task {
            guard let token = UserSession.accessToken,
                  let response = try? await NetworkService.provider.request(with: ProfileEndpoints.get(token: token)),
                  !Task.isCancelled else { return }
            avatarUrl = response.data.avatarUrl
        }
        .task(id: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            isLoadingPhoto = true
            do {
                let photo = try await ProfilePhoto.load(item)
                guard !Task.isCancelled else { return }
                selectedPhoto = photo
                shouldRemovePhoto = false
                saveErrorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                saveErrorMessage = "선택한 사진을 불러오지 못했어요"
            }
            isLoadingPhoto = false
        }
    }

    private func handleBack() {
        if hasUnsavedChanges {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        guard hasUnsavedChanges, validationError == nil, !isSubmitting, !isLoadingPhoto else { return }
        isSubmitting = true
        saveErrorMessage = nil
        defer { isSubmitting = false }

        do {
            let token = UserSession.accessToken
            if nickname != originalNickname {
                if let token {
                    _ = try await NetworkService.provider.request(with: ProfileEndpoints.updateNickname(nickname, token: token))
                    UserSession.nickname = nickname
                } else if let userId = UserSession.userId {
                    let user = try await NetworkService.provider.request(with: UserEndpoints.update(userId: userId, nickname: nickname))
                    UserSession.nickname = user.nickname
                } else {
                    saveErrorMessage = "다시 로그인한 뒤 저장해 주세요"
                    return
                }
                originalNickname = nickname
            }

            if let token, let selectedPhoto {
                let response = try await NetworkService.provider.request(with: ProfileEndpoints.uploadAvatar(selectedPhoto.jpeg, token: token))
                avatarUrl = response.data.avatarUrl
            } else if let token, shouldRemovePhoto {
                try await NetworkService.provider.requestWithoutResponse(with: ProfileEndpoints.removeAvatar(token: token))
                avatarUrl = nil
            }
            dismiss()
        } catch NetworkError.invalidHttpStatusCode(401, _) {
            saveErrorMessage = "다시 로그인한 뒤 저장해 주세요"
        } catch {
            saveErrorMessage = "프로필을 저장하지 못했어요. 다시 시도해 주세요"
        }
    }
}

private extension String {
    /// "특수문자(이모티콘 제외) 사용 가능" 규칙 — 숫자 키캡(0️⃣) 등 isEmoji만으로는 일반 숫자까지
    /// 걸러져서, 기본적으로 이모지로 렌더링되는 isEmojiPresentation까지 같이 확인한다.
    var containsEmoji: Bool {
        unicodeScalars.contains { $0.properties.isEmoji && $0.properties.isEmojiPresentation }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
