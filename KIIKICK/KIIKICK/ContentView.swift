import SwiftUI
import Playgrounds

struct ContentView: View {
    var body: some View {
        Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
            .padding()
    }
}

#Preview {
    ContentView()
}
