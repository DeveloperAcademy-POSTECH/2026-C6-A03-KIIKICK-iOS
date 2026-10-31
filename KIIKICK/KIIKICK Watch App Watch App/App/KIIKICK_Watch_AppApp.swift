//
//  KIIKICK_Watch_AppApp.swift
//  KIIKICK Watch App Watch App
//

import SwiftUI

@main
struct KIIKICK_Watch_App_Watch_AppApp: App {

    var body: some Scene {
        WindowGroup {
            ForPreview()
            .environment(SessionManager.shared)
        }
    }
}
