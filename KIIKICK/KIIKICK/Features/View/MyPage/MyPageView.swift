//
//  MyPageView.swift
//  KIIKICK
//
//  Figma node 392:4459 "my" (iOS 화면)
//

import SwiftUI

struct MyPageView: View {
    @State private var nickname = UserSession.nickname ?? ""
    @State private var avatarUrl: URL?

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
                            ProfilePhotoView(url: avatarUrl, size: 56)

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
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("마이페이지")
        .task {
            nickname = UserSession.nickname ?? ""
            guard let token = UserSession.accessToken else {
                avatarUrl = nil
                return
            }
            if let response = try? await NetworkService.provider.request(with: ProfileEndpoints.get(token: token)),
               !Task.isCancelled {
                avatarUrl = response.data.avatarUrl
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .environment(AppRouter())
}
