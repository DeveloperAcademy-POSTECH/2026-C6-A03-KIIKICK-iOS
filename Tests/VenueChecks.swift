import Foundation
import SwiftData

enum APIConfig { static let baseURL = URL(string: "https://example.invalid")! }
enum UserSession { static let token: String? = "venue-token" }
enum NetworkService { static var provider: any Provider { fatalError("Provider를 주입해야 합니다") } }

final class VenueQueuedSession: URLSessionable {
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
struct VenueChecks {
    @MainActor
    static func main() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Field.self, configurations: configuration)
        let context = container.mainContext
        let session = VenueQueuedSession()
        let provider = ProviderImpl(session: session)

        let venueID = UUID(uuidString: "00000000-0000-4000-8000-000000000075")!
        let createKey = UUID(uuidString: "10000000-0000-4000-8000-000000000075")!
        session.replies = [(201, venueEnvelope(id: venueID, name: "API 경기장"))]
        let corrected = corners(offset: 0)
        let raw = corners(offset: 10)
        let field = try await VenueStore.create(
            name: "API 경기장",
            correctedCorners: corrected,
            rawCorners: raw,
            idempotencyKey: createKey,
            context: context,
            provider: provider
        )
        precondition(field.serverID == venueID && !field.isArchived)
        let fieldsAfterCreate = try context.fetch(FetchDescriptor<Field>())
        precondition(fieldsAfterCreate.count == 1)
        let create = session.requests[0]
        precondition(create.httpMethod == "POST")
        precondition(create.value(forHTTPHeaderField: "Authorization") == "Bearer venue-token")
        precondition(create.value(forHTTPHeaderField: "Idempotency-Key") == createKey.uuidString)
        let body = try JSONSerialization.jsonObject(with: create.httpBody!) as! [String: Any]
        precondition(body["cornerA"] != nil && body["cornerD"] != nil && body["rawCornerD"] != nil)

        let renameKey = UUID(uuidString: "20000000-0000-4000-8000-000000000075")!
        session.replies = [(200, venueEnvelope(
            id: venueID,
            name: "수정 경기장",
            correctedOffset: 20,
            rawOffset: 30
        ))]
        let updatedCorrected = corners(offset: 20)
        let updatedRaw = corners(offset: 30)
        try await VenueStore.update(
            field,
            name: "수정 경기장",
            correctedCorners: updatedCorrected,
            rawCorners: updatedRaw,
            idempotencyKey: renameKey,
            context: context,
            provider: provider
        )
        precondition(field.name == "수정 경기장" && field.cornerA == updatedCorrected[0])
        let rename = session.requests[1]
        precondition(rename.httpMethod == "PATCH" && rename.url?.path.hasSuffix(venueID.uuidString.lowercased()) == true)
        precondition(rename.value(forHTTPHeaderField: "Idempotency-Key") == renameKey.uuidString)
        let updateBody = try JSONSerialization.jsonObject(with: rename.httpBody!) as! [String: Any]
        precondition(updateBody["cornerA"] != nil && updateBody["cornerD"] != nil && updateBody["rawCornerD"] != nil)

        let deleteKey = UUID(uuidString: "30000000-0000-4000-8000-000000000075")!
        session.replies = [(204, Data())]
        try await VenueStore.archive(field, idempotencyKey: deleteKey, context: context, provider: provider)
        precondition(field.isArchived, "삭제 후에도 과거 경기 참조를 위해 로컬 객체를 보존한다")
        let fieldsAfterDelete = try context.fetch(FetchDescriptor<Field>())
        precondition(fieldsAfterDelete.count == 1)
        precondition(session.requests[2].httpMethod == "DELETE")

        let legacy = Field(
            name: "기존 로컬 경기장",
            cornerA: corrected[0], cornerB: corrected[1], cornerC: corrected[2], cornerD: corrected[3],
            rawCornerA: raw[0], rawCornerB: raw[1], rawCornerC: raw[2], rawCornerD: raw[3]
        )
        context.insert(legacy)
        try context.save()
        let list = pageEnvelope(venues: [])
        session.replies = [(200, list), (503, errorBody())]
        do {
            try await VenueStore.synchronize(context: context, provider: provider)
            preconditionFailure("첫 이전 요청은 실패해야 한다")
        } catch NetworkError.invalidHttpStatusCode(503, _) {
            precondition(legacy.createIdempotencyKey != nil)
        }
        let failedRequest = session.requests[4]
        let migrationID = UUID(uuidString: "40000000-0000-4000-8000-000000000075")!
        session.replies = [(200, list), (201, venueEnvelope(id: migrationID, name: legacy.name))]
        try await VenueStore.synchronize(context: context, provider: provider)
        let retriedRequest = session.requests[6]
        precondition(failedRequest.httpBody == retriedRequest.httpBody)
        precondition(
            failedRequest.value(forHTTPHeaderField: "Idempotency-Key")
                == retriedRequest.value(forHTTPHeaderField: "Idempotency-Key")
        )
        precondition(legacy.serverID == migrationID && legacy.createIdempotencyKey == nil)

        print("PASS: 경기장 목록·등록·수정·삭제 API, 좌표 본문, 멱등 재시도, 기록 참조 보존")
    }

    private static func corners(offset: Double) -> [FieldCorner] {
        (0..<4).map { index in
            FieldCorner(latitude: 36 + offset / 100 + Double(index) / 1000,
                        longitude: 127 + offset / 100 + Double(index) / 1000)
        }
    }

    private static func venueEnvelope(
        id: UUID,
        name: String,
        correctedOffset: Double = 0,
        rawOffset: Double = 10
    ) -> Data {
        let corrected = corners(offset: correctedOffset)
        let raw = corners(offset: rawOffset)
        var venue: [String: Any] = [
            "id": id.uuidString.lowercased(),
            "name": name,
            "createdAt": "2026-11-10T09:00:00Z",
            "updatedAt": "2026-11-10T09:00:01Z",
        ]
        for (key, corner) in zip(["cornerA", "cornerB", "cornerC", "cornerD"], corrected) {
            venue[key] = ["latitude": corner.latitude, "longitude": corner.longitude]
        }
        for (key, corner) in zip(["rawCornerA", "rawCornerB", "rawCornerC", "rawCornerD"], raw) {
            venue[key] = ["latitude": corner.latitude, "longitude": corner.longitude]
        }
        return try! JSONSerialization.data(withJSONObject: [
            "data": venue,
            "meta": ["requestId": "venue-check", "serverTime": "2026-11-10T09:00:02Z"],
        ], options: .sortedKeys)
    }

    private static func pageEnvelope(venues: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "data": venues,
            "meta": [
                "requestId": "venue-page",
                "serverTime": "2026-11-10T09:00:02Z",
                "pagination": ["nextCursor": NSNull(), "hasNext": false],
            ],
        ], options: .sortedKeys)
    }

    private static func errorBody() -> Data {
        Data(#"{"error":{"code":"SERVICE_UNAVAILABLE","message":"retry"}}"#.utf8)
    }
}
