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
                LoginView()
            case .main:
                MainView()
                    .environment(SessionManager.shared)
            }
        }
        .animation(.default, value: router.flow)
    }
}

#Preview {
    RootView()
        .environment(AppRouter())
}
