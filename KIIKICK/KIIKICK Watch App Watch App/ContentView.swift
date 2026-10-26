//
//  ContentView.swift
//  KIIKICK Watch App Watch App
//

import SwiftUI

struct ContentView: View {
    @State private var workoutManager = WorkoutManager()

    var body: some View {
        VStack(spacing: 12) {
            Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
            Text("\(workoutManager.points.count)개 측정됨")
            Button(workoutManager.isRunning ? "측정 종료" : "측정 시작") {
                Task {
                    if workoutManager.isRunning {
                        await workoutManager.stop()
                    } else {
                        await workoutManager.start()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
