import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text(SessionManager.shared.isReachable ? "Connected" : "Lost")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List(records) { record in
                    NavigationLink(value: record) {
                        VStack(alignment: .leading) {
                            Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            Text("\(Int(record.totalDistance))m · \(Int(record.duration / 60))분")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationDestination(for: WorkoutRecord.self) { record in
                WorkoutDetailView(record: record)
            }
            .navigationTitle("측정 기록")
        }
    }
}
