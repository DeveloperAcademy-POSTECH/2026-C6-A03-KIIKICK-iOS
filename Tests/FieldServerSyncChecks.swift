import Foundation
import SwiftData

enum APIConfig { static let baseURL = URL(string: "https://example.invalid")! }
enum UserSession { static let token: String? = "sync-token" }
enum NetworkService { static var provider: any Provider { fatalError("Provider를 주입해야 합니다") } }

final class SyncQueuedSession: URLSessionable {
    var replies: [(status: Int, body: Data)] = []
    var requests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        precondition(!replies.isEmpty, "예상하지 못한 요청: \(request.url?.path ?? "")")
        let reply = replies.removeFirst()
        return (
            reply.body,
            HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: nil, headerFields: nil)!
        )
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        fatalError("예상하지 못한 요청")
    }
}

@main
struct FieldServerSyncChecks {
    @MainActor
    static func main() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Field.self, WorkoutRecord.self, configurations: configuration)
        let context = container.mainContext
        let session = SyncQueuedSession()
        let provider = ProviderImpl(session: session)

        // serverID가 이미 있는 운동장이면 VenueStore.ensureUploaded가 네트워크를 타지
        // 않는다 — 덕분에 "호출 없음" 단정이 성립한다(venues 업로드는 check-venues.sh가 덮는다).
        let venueID = UUID(uuidString: "00000000-0000-4000-8000-000000000096")!
        let fieldB = makeField(name: "B구장", serverID: venueID)
        context.insert(fieldB)
        let fresh = makeRecord()
        let submitted = makeRecord()
        context.insert(fresh)
        context.insert(submitted)
        try context.save()

        // 1. 미제출 경기: 서버 호출이 전혀 없다.
        let notSubmitted = try await FieldServerSync.sync(
            records: [fresh], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(notSubmitted == .skippedNotSubmitted)
        precondition(session.requests.isEmpty)

        // 2. 서버에 없는 경기(detail 404): 로컬만 바꾸고 끝난다.
        submitted.submissionIdempotencyKey = UUID()
        submitted.submissionIfMatch = "3"
        try context.save()
        session.replies = [(404, errorBody())]
        let missing = try await FieldServerSync.sync(
            records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(missing == .skippedMatchMissing)

        // 3. 제출된 경기: 최신 version을 읽어 PATCH /matches로 운동장을 반영한다.
        //    서버가 workout-submissions 재전송을 구현하지 않아(2026-11-15 확인) 제출
        //    경로는 아예 타지 않는다 — POST가 한 번도 나가면 안 된다.
        submitted.field = fieldB
        try context.save()
        let keyBeforeSync = submitted.submissionIdempotencyKey
        session.requests.removeAll()
        session.replies = [
            (200, matchDetail(id: submitted.matchId, version: 8)),
            (200, matchDetail(id: submitted.matchId, version: 9)),
        ]
        let patched = try await FieldServerSync.sync(
            records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
        precondition(patched == .matchPatched)
        precondition(session.requests.count == 2)
        precondition(!session.requests.contains { $0.url!.path.hasSuffix("/workout-submissions") })
        let patch = session.requests.last!
        precondition(patch.httpMethod == "PATCH")
        // If-Match는 entity-tag라 따옴표가 필요하다 — 숫자만 보내면 서버가 같은
        // 버전인데도 412 VERSION_CONFLICT로 거절한다(실기기 확인, 이슈 #96).
        precondition(patch.value(forHTTPHeaderField: "If-Match") == "\"8\"")
        let patchBody = try JSONSerialization.jsonObject(with: patch.httpBody!) as! [String: Any]
        precondition((patchBody["venueId"] as! String).lowercased() == venueID.uuidString.lowercased())
        // 제출 식별자는 건드리지 않는다.
        precondition(submitted.submissionIdempotencyKey == keyBeforeSync)

        // 4. PATCH 실패: 에러가 그대로 올라오고(호출부가 로컬 수정은 유지한다)
        //    제출 식별자는 건드리지 않는다.
        session.requests.removeAll()
        session.replies = [
            (200, matchDetail(id: submitted.matchId, version: 10)),
            (412, errorBody()),
        ]
        do {
            _ = try await FieldServerSync.sync(
                records: [submitted], positions: ["CM"], field: fieldB, context: context, provider: provider)
            preconditionFailure("실패가 전달되지 않았습니다")
        } catch {
            precondition(submitted.submissionIdempotencyKey == keyBeforeSync)
        }

        print("FieldServerSyncChecks 통과")
    }

    private static func makeField(name: String, serverID: UUID?) -> Field {
        let corners = (0..<4).map { index in
            FieldCorner(latitude: 36.0 + Double(index) * 0.001, longitude: 129.0 + Double(index) * 0.001)
        }
        return Field(
            name: name,
            cornerA: corners[0], cornerB: corners[1], cornerC: corners[2], cornerD: corners[3],
            serverID: serverID
        )
    }

    private static func makeRecord() -> WorkoutRecord {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let points = (0..<3).map { index in
            TrackPoint(
                latitude: 36.0 + Double(index) * 0.0001, longitude: 129.0 + Double(index) * 0.0001,
                altitude: 20, horizontalAccuracy: 5, speed: 2, course: 90,
                timestamp: start.addingTimeInterval(Double(index) * 5)
            )
        }
        return WorkoutRecord(payload: WorkoutPayload(
            startDate: start,
            endDate: start.addingTimeInterval(600),
            points: points,
            heartRateSamples: [HeartRateSample(timestamp: start, bpm: 120)],
            totalCalories: 100,
            totalDistance: 1000,
            events: [],
            field: nil,
            position: .cm
        ))
    }

    private static func matchDetail(id: UUID, version: Int) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "data": [
                "id": id.uuidString.lowercased(),
                "ownerId": "00000000-0000-4000-8000-000000000001",
                "title": NSNull(),
                "venueId": NSNull(),
                "venueSnapshot": NSNull(),
                "scheduledAt": NSNull(),
                "status": "COMPLETED",
                "startedAt": NSNull(),
                "endedAt": NSNull(),
                "version": version,
                "createdAt": "2026-11-14T09:00:00Z",
                "updatedAt": "2026-11-14T09:00:01Z",
            ],
            "meta": ["requestId": "field-sync-check", "serverTime": "2026-11-14T09:00:02Z"],
        ], options: .sortedKeys)
    }

    private static func errorBody() -> Data {
        Data(#"{"error":{"code":"CONFLICT","message":"conflict"}}"#.utf8)
    }
}
