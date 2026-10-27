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
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppRouter.AppTab.home)
        }
    }
}

#Preview {
    MainView()
        .environment(AppRouter())
}
