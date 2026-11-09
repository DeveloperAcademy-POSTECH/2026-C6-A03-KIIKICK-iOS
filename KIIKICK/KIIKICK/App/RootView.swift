//
//  RootView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        Group {
            switch router.flow {
            case .splash:
                SplashView()
            case .auth:
                StartView()
            case .main:
                MainView()
                    .environment(SessionManager.shared)
            }
        }
        .animation(.default, value: router.flow)
        .dismissKeyboardOnTap()
        .onAppear {
            Task {
                // sleep(1)
                // 이슈 #63: accessToken이 만료됐으면 refreshToken으로 재인증한다 —
                // 실패(refreshToken도 무효)하면 세션이 지워진 채로 false가 돌아온다.
                let isLoggedIn = await UserSession.reauthenticateIfNeeded()
                router.finishSplash(isLoggedIn: isLoggedIn)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
}
