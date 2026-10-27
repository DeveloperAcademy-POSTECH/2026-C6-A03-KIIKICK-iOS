import SwiftUI
import SwiftData

@main struct MyApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = try! ModelContainer(for: WorkoutRecord.self, Field.self)
        SessionManager.shared.modelContext = modelContainer.mainContext
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
