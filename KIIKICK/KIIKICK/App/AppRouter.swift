//
//  AppRouter.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI

@MainActor @Observable
final class AppRouter {
    var path: NavigationPath = .init()
    
    enum AppFlow {
        case splash
        case auth
        case main
    }
    
    enum AppTab: Hashable {
        case home, friends, analysis, myPage
        #if DEBUG
        case devAuth
        #endif
    }
    
    enum Route: Hashable {
        case profile
        case matchDetail(WorkoutRecord)
        case search
    }
    
    var flow: AppFlow = .splash
    var selection: AppTab = .home
    var paths: [AppTab: NavigationPath] = [:]
    
    func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }
    
    func push(_ route: Route, in tab: AppTab? = nil) {
        let target = tab ?? selection
        selection = target
        paths[target, default: .init()].append(route)
    }
    
    func pop() {
        guard paths[selection]?.isEmpty == false else { return }
        paths[selection]?.removeLast()
    }
    
    func popToRoot() {
        paths[selection] = .init()
    }
}

extension AppRouter {
    func finishSplash(isLoggedIn: Bool) {
        if !isLoggedIn {
            flow = .auth
        } else {
            flow = .main
        }
    }
    
    func didLogIn() { flow = .main }
    func didLogOut() { reset(); flow = .auth }
    func didSignOut() { reset(); flow = .auth }
    
    private func reset() {
        selection = .home
        paths = [:]
    }
}
