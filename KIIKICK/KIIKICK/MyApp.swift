import SwiftUI
import SwiftData

@main struct MyApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        modelContainer = try! ModelContainer(for: WorkoutRecord.self)
        SessionManager.shared.modelContext = modelContainer.mainContext
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SessionManager.shared)
        }
        .modelContainer(modelContainer)
    }
}
