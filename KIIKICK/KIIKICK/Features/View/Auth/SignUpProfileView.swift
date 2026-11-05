//
//  SignUpProfileView.swift
//  KIIKICK
//
//  Figma node 575:9884 "signup_04"(사진 설정, 4/4단계) / 575:9916 "signup_05"(환영 메시지) — iOS 화면
//
//  DESIGN-GAP: 사진은 EditProfileView와 동일하게 로컬 PhotosPicker 미리보기만 가능하고
//  서버에 업로드되지 않는다(UserResponse에 사진 필드가 없음). 회원가입 API도 아직 없어
//  (Auth API 변경 예정) "가입 완료"는 실제 계정을 만들지 않고, 환영 화면을 보여준 뒤
//  로그인과 동일하게 mock 토큰만 저장하고 메인으로 진입시킨다.
//

import SwiftUI
import PhotosUI

struct SignUpProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let nickname: String

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: Image?
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

            CtaView(text: "가입 완료", type: .primary, size: .large) {
                withAnimation { isWelcoming = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    completeSignUp()
                }
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

    private func completeSignUp() {
        UserSession.saveToken(UUID().uuidString)
        UserSession.nickname = nickname
        router.didLogIn()
    }
}

#Preview {
    NavigationStack {
        SignUpProfileView(nickname: "효자동 조규성")
            .environment(AppRouter())
    }
}
