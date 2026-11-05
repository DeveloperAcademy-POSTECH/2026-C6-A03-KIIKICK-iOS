//
//  KIIKICK_Watch_AppApp.swift
//  KIIKICK Watch App Watch App
//

import SwiftUI
import SwiftData

@main
struct KIIKICK_Watch_App_Watch_AppApp: App {

    let modelContainer: ModelContainer

    init() {
        modelContainer = try! ModelContainer(for: QuarterRecord.self)
        SessionManager.shared.modelContext = modelContainer.mainContext
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(SessionManager.shared)
        }
        .modelContainer(modelContainer)
    }
}
