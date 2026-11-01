//
//  MainView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI

struct MainView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        TabView(selection: $router.selection) {
            NavigationStack(path: router.path(for: .home)) {
                HomeView()
            }
            .tabItem { Label("홈", systemImage: "house") }
            .tag(AppRouter.AppTab.home)
            NavigationStack(path: router.path(for: .friends)) {
                FriendsView()
            }
                .tabItem { Label("친구", systemImage: "figure.2.right.holdinghands") }
                .tag(AppRouter.AppTab.friends)
            NavigationStack(path: router.path(for: .analysis)) {
                AnalysisView()
            }
                .tabItem { Label("분석", systemImage: "document") }
                .tag(AppRouter.AppTab.analysis)
            NavigationStack(path: router.path(for: .myPage)) {
                MyPageView()
            }
                .tabItem { Label("마이페이지", systemImage: "person.fill") }
                .tag(AppRouter.AppTab.myPage)
            #if DEBUG
            NavigationStack(path: router.path(for: .devAuth)) {
                DevAuthView()
            }
                .tabItem { Label("로그인(테스트)", systemImage: "ladybug") }
                .tag(AppRouter.AppTab.devAuth)
            #endif
        }
    }
}

#Preview {
    MainView()
        .environment(AppRouter())
}
