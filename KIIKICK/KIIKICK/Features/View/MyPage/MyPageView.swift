//
//  MyPageView.swift
//  KIIKICK
//
//  Figma node 392:4459 "my" (iOS 화면)
//

import SwiftUI

struct MyPageView: View {
    private let nickname = UserSession.nickname ?? ""

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
                            Image("img_profile_default")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("마이페이지")
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
    .environment(AppRouter())
}
