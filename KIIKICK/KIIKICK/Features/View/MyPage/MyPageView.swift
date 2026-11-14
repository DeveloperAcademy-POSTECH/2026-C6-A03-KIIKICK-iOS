//
//  MyPageView.swift
//  KIIKICK
//
//  Figma node 392:4459 "my" (iOS 화면)
//

import SwiftUI

struct MyPageView: View {
    @AppStorage("nickname") private var nickname = ""
    @State private var profileError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("프로필")
                        .font(.title2SB)
                        .foregroundStyle(.gray50)

                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: 16) {
                            CurrentUserAvatarView()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())

                            Text(nickname)
                                .font(.title2SB)
                                .foregroundStyle(.gray50)

                            Spacer()

                            Text("프로필 수정")
                                .font(.label4SB)
                                .foregroundStyle(.mint500)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 96)
                        .background(Color.gray850, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("설정")
                        .font(.title2SB)
                        .foregroundStyle(.gray50)

                    VStack(spacing: 12) {
                        NavigationLink {
                            SetNotificationView()
                        } label: {
                            NaviRowView(text: "알림 설정", textStyle: .title3M)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AccountView()
                        } label: {
                            NaviRowView(text: "계정 관리", textStyle: .title3M)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("고객 지원")
                        .font(.title2SB)
                        .foregroundStyle(.gray50)

                    Button {
                        if let url = URL(string: "https://open.kakao.com/o/g72l1tVi") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        NaviRowView(text: "문의하기", textStyle: .title3M, trailingIconName: "ic_link")
                    }
                    .buttonStyle(.plain)

                    if let privacyPolicyURL = URL(string: "https://dazzling-myth-cd2.notion.site/4147c67ff1e6803ba4ffcbd704fa49cd?source=copy_link") {
                        Link(destination: privacyPolicyURL) {
                            NaviRowView(text: "개인정보 처리방침", textStyle: .title3M, trailingIconName: "ic_link")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("마이페이지")
        .task { await loadProfile() }
        .alert("프로필을 불러오지 못했어요", isPresented: Binding(
            get: { profileError != nil },
            set: { if !$0 { profileError = nil } }
        )) {
            Button("다시 시도") { Task { await loadProfile() } }
            Button("닫기", role: .cancel) {}
        } message: {
            Text(profileError ?? "")
        }
    }

    private func loadProfile() async {
        guard let ownerId = UserSession.userId, UserSession.token != nil else { return }
        do {
            try await UserSession.refreshProfile()
        } catch {
            guard !Task.isCancelled, UserSession.userId == ownerId else { return }
            profileError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .environment(AppRouter())
}
