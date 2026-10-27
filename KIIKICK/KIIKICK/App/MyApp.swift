import SwiftUI
import SwiftData

@main struct MyApp: App {

    @State private var router = AppRouter()
    let modelContainer: ModelContainer

    init() {
        modelContainer = try! ModelContainer(for: WorkoutRecord.self, Field.self)
        SessionManager.shared.modelContext = modelContainer.mainContext
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
        }
        .modelContainer(modelContainer)
    }
}
