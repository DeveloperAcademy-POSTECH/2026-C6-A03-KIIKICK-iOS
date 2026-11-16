//
//  EditProfileView.swift
//  KIIKICK
//
//  Figma node 392:4477 "editProfile", 392:4629 "Alert"(나가기 확인) — iOS 화면
//
//  선택한 사진은 JPEG로 변환해 업로드하고, 반환된 URL을 UserSession에 저장한다.
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
    @State private var selectedPhoto: Image?
    @State private var selectedPhotoData: Data?
    @State private var isLoadingPhoto = false
    @State private var mockHeatmapTheme: MockHeatmapTheme

    @State private var originalNickname: String
    @State private var originalMockHeatmapTheme: MockHeatmapTheme

    init() {
        let current = UserSession.nickname ?? ""
        _nickname = State(initialValue: current)
        _originalNickname = State(initialValue: current)
        let currentTheme = UserSession.mockHeatmapTheme
        _mockHeatmapTheme = State(initialValue: currentTheme)
        _originalMockHeatmapTheme = State(initialValue: currentTheme)
    }

    private var hasUnsavedChanges: Bool {
        nickname != originalNickname || mockHeatmapTheme != originalMockHeatmapTheme || selectedPhotoData != nil || isLoadingPhoto
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
                    ZStack {
                        if let selectedPhoto {
                            selectedPhoto
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            CurrentUserAvatarView()
                        }
                    }
                    .frame(width: 99, height: 99)
                    .clipShape(Circle())
                }
                .disabled(isSubmitting)
                Text("프로필 사진 변경")
                    .font(.caption1M)
                    .foregroundStyle(.mint500)
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

            VStack(alignment: .leading, spacing: 12) {
                Text("분석 데이터 테마")
                    .font(.body4R)
                    .foregroundStyle(.gray400)
                Text("이 계정의 목업 히트맵에는 선택한 포지션 데이터만 표시돼요.")
                    .font(.caption1M)
                    .foregroundStyle(.gray500)

                VStack(spacing: 8) {
                    ForEach(MockHeatmapTheme.allCases, content: themeRow)
                }
            }

            Spacer()

            CtaView(text: "저장", type: .primary, isActive: validationError == nil && !isSubmitting && !isLoadingPhoto) {
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
            }
        }
        .alert("프로필 수정을 그만둘까요?", isPresented: $isPresentingLeaveConfirm) {
            Button("계속 수정", role: .cancel) {}
            Button("나가기", role: .destructive) { dismiss() }
        } message: {
            Text("변경한 내용은 저장되지 않아요.")
        }
        .task(id: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            isLoadingPhoto = true
            selectedPhoto = nil
            selectedPhotoData = nil
            saveErrorMessage = nil
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
                selectedPhotoData = avatar.jpegData
            } catch {
                guard !Task.isCancelled, selectedPhotoItem == item else { return }
                saveErrorMessage = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func themeRow(for theme: MockHeatmapTheme) -> some View {
        let isSelected = mockHeatmapTheme == theme
        Button {
            mockHeatmapTheme = theme
            saveErrorMessage = nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: theme.symbolName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .mint500 : .gray400)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.displayName)
                        .font(.body1M)
                        .foregroundStyle(.gray50)
                    Text("\(theme.role) · \(theme.description)")
                        .font(.caption1M)
                        .foregroundStyle(.gray400)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.mint500)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray850, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.mint500 : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName), \(theme.role)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func handleBack() {
        guard !isSubmitting else { return }
        if hasUnsavedChanges {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        guard !isSubmitting, !isLoadingPhoto, validationError == nil else { return }
        guard let ownerId = UserSession.userId, UserSession.token != nil else {
            saveErrorMessage = "로그인이 필요해요. 다시 로그인해 주세요"
            return
        }
        isSubmitting = true
        saveErrorMessage = nil
        defer { isSubmitting = false }

        do {
            if nickname != originalNickname {
                let profile = try await NetworkService.provider.request(with: AuthEndpoints.updateProfile(nickname: nickname))
                guard UserSession.userId == ownerId else { return }
                UserSession.update(profile: profile.data)
                // 닉네임 저장 후 사진 업로드만 실패하면 재시도 시 사진만 다시 전송한다.
                originalNickname = profile.data.nickname ?? nickname
                nickname = originalNickname
            }
            if let selectedPhotoData {
                let avatar = try await NetworkService.provider.request(with: AvatarEndpoints.upload(jpegData: selectedPhotoData))
                guard UserSession.userId == ownerId else { return }
                UserSession.saveAvatar(url: avatar.data.avatarUrl, for: ownerId, imageData: selectedPhotoData)
                self.selectedPhotoData = nil
            }
            UserSession.mockHeatmapTheme = mockHeatmapTheme
            originalMockHeatmapTheme = mockHeatmapTheme
            dismiss()
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            saveErrorMessage = message ?? "프로필을 모두 저장하지 못했어요. 다시 시도해 주세요"
        } catch {
            saveErrorMessage = "프로필을 모두 저장하지 못했어요. 다시 시도해 주세요"
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
