//
//  EditProfileView.swift
//  KIIKICK
//
//  Figma node 392:4477 "editProfile", 392:4629 "Alert"(나가기 확인) — iOS 화면
//
//  DESIGN-GAP: 프로필 사진은 로컬 PhotosPicker로 미리보기만 가능하다. 서버에 사진을 올리는
//  API가 아직 없어(UserResponse에 사진 필드 자체가 없음) 선택한 사진은 저장되지 않는다.
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

    private let originalNickname: String

    init() {
        let current = UserSession.nickname ?? ""
        _nickname = State(initialValue: current)
        originalNickname = current
    }

    private var hasUnsavedChanges: Bool { nickname != originalNickname }

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
                            Image("img_profile_default")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 99, height: 99)
                    .clipShape(Circle())
                }
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
                .onChange(of: nickname) { saveErrorMessage = nil }
            }

            Spacer()

            CtaView(text: "저장", type: .primary, isActive: validationError == nil && !isSubmitting) {
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                selectedPhoto = Image(uiImage: uiImage)
            }
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
        guard let userId = UserSession.userId, validationError == nil else { return }
        isSubmitting = true
        saveErrorMessage = nil
        defer { isSubmitting = false }

        do {
            let user = try await NetworkService.provider.request(with: UserEndpoints.update(userId: userId, nickname: nickname))
            UserSession.nickname = user.nickname
            dismiss()
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            saveErrorMessage = message ?? "닉네임을 저장하지 못했어요. 다시 시도해 주세요"
        } catch {
            saveErrorMessage = "닉네임을 저장하지 못했어요. 다시 시도해 주세요"
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
