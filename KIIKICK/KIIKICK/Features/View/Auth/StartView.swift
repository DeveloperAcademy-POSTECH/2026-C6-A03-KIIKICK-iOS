//
//  StartView.swift
//  KIIKICK
//
//  Figma node 575:9907 "start" (iOS 화면) — 온보딩 진입 화면
//

import SwiftUI

struct StartView: View {
    @State private var isPresentingLogin = false
    @State private var isPresentingSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 238, height: 119)

                    VStack(spacing: 12) {
                        Text("내가 뛴 만큼, 보이는 나의 플레이")
                        Text("KIIKICK")
                    }
                    .font(.title2SB)
                    .foregroundStyle(.gray50)
                }

                Spacer()

                VStack(spacing: 8) {
                    CtaView(text: "로그인", type: .primary, size: .large) {
                        isPresentingLogin = true
                    }
                    CtaView(text: "이메일로 시작하기", type: .secondary, size: .large) {
                        isPresentingSignUp = true
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray950)
            .navigationDestination(isPresented: $isPresentingLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $isPresentingSignUp) {
                SignUpEmailView()
            }
        }
    }
}

#Preview {
    StartView()
        .environment(AppRouter())
}
