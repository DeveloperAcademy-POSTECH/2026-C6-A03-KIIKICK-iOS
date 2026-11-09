//
//  SignUpProfileView.swift
//  KIIKICK
//
//  Figma node 575:9884 "signup_04"(사진 설정, 4/4단계) / 575:9916 "signup_05"(환영 메시지) — iOS 화면
//
//  DESIGN-GAP: 사진은 EditProfileView와 동일하게 로컬 PhotosPicker 미리보기만 가능하고
//  서버에 업로드되지 않는다 — avatar 업로드는 multipart/form-data인데 현재 Provider/
//  Endpoint는 JSON 바디만 지원해서 범위 밖(AuthEndpoints.swift 주석 참고).
//
//  "가입 완료"에서 AuthEndpoints.signup(registrationToken, password)으로 실제 계정을
//  만든다. signup 응답에는 닉네임이 없어(서버가 안 받음) 성공 직후 updateProfile로
//  닉네임을 한 번 더 저장한다. 둘 다 성공해야 환영 화면으로 넘어간다.
//

import SwiftUI
import PhotosUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let registrationToken: String
    let password: String
    let nickname: String

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: Image?
    @State private var isWelcoming = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                selectedPhoto = Image(uiImage: uiImage)
            }
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

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption1M)
                    .foregroundStyle(.red500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            CtaView(text: "가입 완료", type: .primary, size: .large, isActive: !isSubmitting) {
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
                    Image("img_profile_default")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(Circle())

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
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let session = try await NetworkService.provider.request(
                with: AuthEndpoints.signup(registrationToken: registrationToken, password: password)
            )
            UserSession.save(session: session.data)

            let profile = try await NetworkService.provider.request(with: AuthEndpoints.updateProfile(nickname: nickname))
            UserSession.nickname = profile.data.nickname ?? nickname

            withAnimation { isWelcoming = true }
            try? await Task.sleep(for: .seconds(1.2))
            router.didLogIn()
        } catch let NetworkError.invalidHttpStatusCode(_, message) {
            errorMessage = message ?? "회원가입에 실패했어요. 다시 시도해 주세요"
        } catch {
            errorMessage = "회원가입에 실패했어요. 다시 시도해 주세요"
        }
    }
}

#Preview {
    NavigationStack {
        SignUpProfileView(registrationToken: "preview-token", password: "preview-password1!", nickname: "효자동 조규성")
            .environment(AppRouter())
    }
}
