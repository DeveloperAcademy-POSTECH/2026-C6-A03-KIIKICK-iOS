//
//  ContentView.swift
//  KIIKICK Watch App Watch App
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
            .padding()
    }
}

#Preview {
    ContentView()
}
