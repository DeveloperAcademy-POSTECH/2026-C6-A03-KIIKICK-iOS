import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \WorkoutRecord.date, order: .reverse) private var records: [WorkoutRecord]

    @State private var preparedField: Field?
    @State private var isSelectingField = false

    private var matchState: HomeMatchState {
        if sessionManager.isMatchInProgress {
            return .inProgress
        }
        if let record = sessionManager.justArrivedRecord {
            return .justFinished(record: record)
        }
        if let preparedField {
            return .prepared(fieldName: preparedField.name)
        }
        return .readyToPrepare
    }

    var body: some View {
        VStack(spacing: 8) {
            MatchStatusHeaderView(
                state: matchState,
                onPrepareMatch: { isSelectingField = true },
                onForceEndMatch: {
                    // TODO: 워치 쪽에 "강제 종료"를 전달하는 API가 아직 없어 UI만 구현.
                }
            )
            .navigationDestination(isPresented: $isSelectingField) {
                FieldListView(onSelect: { field in
                    preparedField = field
                    isSelectingField = false
                })
            }
            .onChange(of: sessionManager.isMatchInProgress) { _, isInProgress in
                if isInProgress { preparedField = nil }
            }
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
            .navigationDestination(for: WorkoutRecord.self) { record in
                WorkoutDetailView(record: record)
                    .toolbar(.hidden, for: .tabBar)
                    .onAppear {
                        if sessionManager.justArrivedRecord?.persistentModelID == record.persistentModelID {
                            sessionManager.justArrivedRecord = nil
                        }
                    }
            }
            .navigationTitle("측정 기록")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("운동장") {
                        FieldListView()
                    }
                }
            }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("테스트 데이터 추가") {
                        modelContext.insert(WorkoutRecord(payload: .fake()))
                        try? modelContext.save()
                    }
                }
            }
            #endif
        }
    }
}
