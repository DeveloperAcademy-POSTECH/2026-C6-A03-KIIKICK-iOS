//
//  MainView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(AppRouter.self) private var router
    @Environment(SessionManager.self) private var sessionManager
    
    var body: some View {
        @Bindable var router = router
        @Bindable var sessionManager = sessionManager
        
        TabView(selection: $router.selection) {
            NavigationStack(path: router.path(for: .home)) {
                HomeView()
                    .navigationDestination(for: AppRouter.NotificationRoute.self) { _ in
                        NotificationListView(notifications: $sessionManager.notifications)
                    }
                    .modifier(AnalysisRouteDestinations(tab: .home))
            }
            // 이슈 #42: Figma "overall" 프레임부터는 이 탭이 집 아이콘이 아니라
            // "OVR" 글자 탭으로 바뀌었다. DESIGN-GAP: 실제 탭바 아이콘 에셋을 받지
            // 못해 SF Symbol(스파크라인 모양)로 대체했다.
            .tabItem { Label("OVR", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppRouter.AppTab.home)
            
            NavigationStack(path: router.path(for: .friends)) {
                FriendsView()
            }
                .tabItem { Label("친구", systemImage: "person.2.fill") }
                .tag(AppRouter.AppTab.friends)

            NavigationStack(path: router.path(for: .analysis)) {
                AnalysisView()
                    .modifier(AnalysisRouteDestinations(tab: .analysis))
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
        .environment(SessionManager.shared)
        .modelContainer(for: [WorkoutRecord.self, Field.self], inMemory: true)
}
