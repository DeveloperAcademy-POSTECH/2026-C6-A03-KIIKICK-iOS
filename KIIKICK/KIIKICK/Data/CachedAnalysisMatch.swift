import Foundation
import SwiftData

/// 서버에서 내려받은 경기 결과와 샘플을 기기에 보관한다.
@Model
final class CachedAnalysisMatch {
    var matchID: UUID
    var ownerID: UUID
    var snapshotData: Data
    var savedAt: Date
    @Transient private var decodedEntry: AnalysisEntry?

    init(matchID: UUID, ownerID: UUID, snapshot: OwnMatchAnalysisSnapshot) throws {
        self.matchID = matchID
        self.ownerID = ownerID
        self.snapshotData = try JSONEncoder().encode(snapshot)
        self.savedAt = Date()
    }

    @MainActor var entry: AnalysisEntry? {
        if let decodedEntry { return decodedEntry }
        guard let snapshot = try? JSONDecoder().decode(OwnMatchAnalysisSnapshot.self, from: snapshotData) else { return nil }
        decodedEntry = OwnMatchAnalysisLoader.entry(from: snapshot)
        return decodedEntry
    }
}
