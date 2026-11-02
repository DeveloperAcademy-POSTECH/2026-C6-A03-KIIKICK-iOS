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
            .tabItem { Label("홈", systemImage: "house.fill") }
            .tag(AppRouter.AppTab.home)
            
            NavigationStack(path: router.path(for: .friends)) {
                FriendsView()
            }
                .tabItem { Label("친구", systemImage: "person.2.fill") }
                .tag(AppRouter.AppTab.friends)
            
            NavigationStack(path: router.path(for: .analysis)) {
                AnalysisView()
            }
                .tabItem { Label("분석", systemImage: "chart.bar.fill") }
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
        .tint(.mint500)
        // DESIGN-GAP: 탭바 배경/선택색은 Figma master component(241:916)를 이번 세션에
        // 재검증하지 못해 gray900/mint500으로 가정했다.
        .toolbarBackground(Color.gray900, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    MainView()
        .environment(AppRouter())
}
