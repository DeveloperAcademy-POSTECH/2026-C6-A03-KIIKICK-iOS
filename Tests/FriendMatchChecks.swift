import Foundation
import SwiftUI

// 실제 Provider/Endpoint/DTO/목록·댓글 모델을 사용한다. 네트워크와 인증 저장소만 대체한다.
enum APIConfig { static let baseURL = URL(string: "https://example.invalid")! }
enum UserSession { static let token: String? = "fixture-token" }
enum NetworkService { static var provider: any Provider { fatalError("Provider를 주입해야 합니다") } }

final class QueuedSession: URLSessionable {
    var replies: [(status: Int, body: Data)] = []
    var requests: [URLRequest] = []
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        precondition(!replies.isEmpty, "예상하지 못한 요청: \(request.url?.path ?? "")")
        let reply = replies.removeFirst()
        await Task.yield()
        return (reply.body, HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: nil, headerFields: nil)!)
    }
    func data(from url: URL) async throws -> (Data, URLResponse) { fatalError("예상하지 못한 요청") }
}

@main struct FriendMatchChecks {
    @MainActor static func main() async throws {
        let fixtures = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))) as! [String: Any]
        func data(_ key: String) throws -> Data { try JSONSerialization.data(withJSONObject: fixtures[key]!, options: .sortedKeys) }
        func modified(_ key: String, _ change: (inout [String: Any]) -> Void) throws -> Data {
            var object = fixtures[key] as! [String: Any]
            change(&object)
            return try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
        }
        let owner = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
        let match = UUID(uuidString: "00000000-0000-4000-8000-000000000002")!
        let session = QueuedSession()
        let provider = ProviderImpl(session: session)
        let model = FriendMatchListModel(userID: owner, provider: provider)
        session.replies = [(200, try data("list")), (200, try data("result")), (200, try data("quarters"))]
        await model.reload()
        precondition(session.replies.isEmpty && model.entries.count == 1 && model.errorMessage == nil)
        let entry = model.entries[0].entry
        precondition(entry.id == match && entry.records.isEmpty, "친구 데이터를 로컬 운동 기록으로 저장하지 않는다")
        precondition(entry.detail.quarters[0].field?.name == "테스트 경기장")
        precondition(entry.detail.quarters[0].resultGoals == 1 && entry.detail.quarters[0].resultAssists == 0)
        precondition(entry.detail.quarters[0].resultStats?[0].value == "28.8", "서버 m/s를 km/h로 변환한다")
        precondition(entry.detail.quarters[0].resultSections?.count == 2)
        precondition(session.requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer fixture-token" })
        precondition(URLComponents(url: session.requests[0].url!, resolvingAgainstBaseURL: false)?.queryItems?.contains(URLQueryItem(name: "status", value: "COMPLETED")) == true)

        // 쿼터의 workout.field가 빠져도 친구 경기장 API의 좌표로 맵을 구성한다.
        let venueSession = QueuedSession()
        let venueProvider = ProviderImpl(session: venueSession)
        let venueResponse: [String: Any] = [
            "data": ["id": match.uuidString, "name": "친구 경기장", "address": "테스트 주소",
                "cornerA": ["latitude": 37.0, "longitude": 127.0],
                "cornerB": ["latitude": 37.0, "longitude": 127.001],
                "cornerC": ["latitude": 37.001, "longitude": 127.001],
                "cornerD": ["latitude": 37.001, "longitude": 127.0],
                "createdAt": "2026-11-10T12:00:00+09:00", "updatedAt": "2026-11-10T12:00:00+09:00"],
            "meta": (fixtures["result"] as! [String: Any])["meta"]!
        ]
        venueSession.replies = [(200, try data("result")),
            (200, try modified("quarters") { object in
                var rows = object["data"] as! [[String: Any]]
                var workout = rows[0]["workout"] as! [String: Any]
                workout["field"] = NSNull()
                rows[0]["workout"] = workout
                object["data"] = rows
            }), (200, try JSONSerialization.data(withJSONObject: venueResponse))]
        let venueAnalysis = try await FriendMatchLoader.load(userID: owner, matchID: match, provider: venueProvider)
        precondition(venueAnalysis?.entry.detail.quarters[0].field?.name == "친구 경기장")
        precondition(venueSession.requests.last?.url?.path.hasSuffix("/venue") == true)

        // 미제출 경기만 있는 페이지 뒤에 공개된 경기가 있어도 계속 조회한다.
        session.replies = [
            (200, try modified("list") { object in
                var meta = object["meta"] as! [String: Any]
                meta["pagination"] = ["nextCursor": "page-2", "hasNext": true]
                object["meta"] = meta
            }), (200, try data("result")),
            (200, try modified("quarters") { object in
                var quarters = object["data"] as! [[String: Any]]
                quarters[0]["workout"] = NSNull()
                object["data"] = quarters
            }), (200, try data("list")), (200, try data("result")), (200, try data("quarters"))]
        await model.reload()
        precondition(session.replies.isEmpty && model.entries.count == 1 && !model.hasNext)
        precondition(session.requests.contains { $0.url?.query?.contains("cursor=page-2") == true })

        // 쿼터 페이지를 모두 읽고, 계산 중인 값은 0으로 만들어 표시하지 않는다.
        let secondQuarter = try modified("quarters") { object in
            var rows = object["data"] as! [[String: Any]]
            var quarter = rows[0]["quarter"] as! [String: Any]
            let secondID = "00000000-0000-4000-8000-000000000007"
            quarter["id"] = secondID; quarter["number"] = 2
            rows[0]["quarter"] = quarter
            var position = rows[0]["position"] as! [String: Any]
            position["quarterId"] = secondID
            rows[0]["position"] = position
            var workout = rows[0]["workout"] as! [String: Any]
            workout["quarterId"] = secondID
            rows[0]["workout"] = workout
            var summary = rows[0]["summary"] as! [String: Any]
            summary["quarterId"] = secondID; summary["calculationStatus"] = "PROCESSING"
            rows[0]["summary"] = summary
            object["data"] = rows
        }
        session.replies = [
            (200, try modified("result") { object in
                var value = object["data"] as! [String: Any]
                value["quarterCount"] = 2; object["data"] = value
            }),
            (200, try modified("quarters") { object in
                var meta = object["meta"] as! [String: Any]
                meta["pagination"] = ["nextCursor": "quarter-2", "hasNext": true]
                object["meta"] = meta
            }), (200, secondQuarter)]
        let full = try await FriendMatchLoader.load(userID: owner, matchID: match, provider: provider)
        precondition(full?.entry.detail.quarters.count == 2)
        precondition(full?.entry.detail.quarters[0].resultStats?[0].value == "28.8")
        precondition(full?.entry.detail.quarters[1].resultStats?[0].value == "—")
        precondition(full?.entry.detail.quarters[1].resultSections?.isEmpty == true)

        // 친구 히트맵은 원본 경로가 아닌 서버가 집계한 격자와 표본 수를 사용한다.
        let heatmapSession = QueuedSession()
        let heatmap = FriendHeatmapModel(
            userID: owner,
            matchID: match,
            quarterID: entry.detail.quarters[0].id,
            provider: ProviderImpl(session: heatmapSession)
        )
        heatmapSession.replies = [(200, try data("heatmap"))]
        await heatmap.loadIfNeeded()
        precondition(heatmap.errorMessage == nil && heatmap.heatmap?.sampleCount == 7)
        precondition(heatmap.heatmap?.cells.map(\.sampleCount) == [5, 2])
        precondition(
            heatmapSession.requests[0].url?.path ==
                "/api/v1/friends/00000000-0000-4000-8000-000000000001/matches/00000000-0000-4000-8000-000000000002/quarters/00000000-0000-4000-8000-000000000003/heatmap"
        )

        session.replies = [(403, Data(#"{"error":{"code":"FORBIDDEN","message":"denied"}}"#.utf8))]
        await model.reload()
        precondition(model.entries.isEmpty && model.errorMessage != nil, "접근 권한 상실 시 이전 경기 노출 금지")

        let commentsSession = QueuedSession()
        let comments = MatchCommentsModel(matchID: match, provider: ProviderImpl(session: commentsSession))
        commentsSession.replies = [(200, try data("comments")), (200, try data("profile"))]
        await comments.loadInitial()
        precondition(comments.comments.count == 1, "중복 댓글 ID를 제거한다")
        precondition(comments.displayedComments[0].authorNickname == "친구")
        precondition(commentsSession.requests.count == 2, "작성자 프로필은 중복 조회하지 않는다")
        comments.draft = String(repeating: "a", count: 1001)
        precondition(!comments.canSend && comments.validationMessage != nil)
        await comments.send()
        precondition(commentsSession.requests.count == 2)
        comments.draft = "좋은 경기였어!"
        commentsSession.replies = [(503, Data(#"{"error":{"code":"SERVICE_UNAVAILABLE","message":"retry"}}"#.utf8)), (201, try data("created"))]
        await comments.send()
        precondition(comments.draft == "좋은 경기였어!" && comments.errorMessage != nil && comments.comments.count == 1)
        await comments.send()
        precondition(comments.draft.isEmpty && comments.comments.count == 2 && comments.errorMessage == nil)
        let posts = commentsSession.requests.filter { $0.httpMethod == "POST" }
        precondition(posts.count == 2 && posts[0].httpBody == posts[1].httpBody)
        let key = posts[0].value(forHTTPHeaderField: "Idempotency-Key")!
        precondition(UUID(uuidString: key) != nil && key == posts[1].value(forHTTPHeaderField: "Idempotency-Key"))
        let delete = try MatchCommentEndpoints.delete(matchID: match, commentID: comments.comments[0].id, idempotencyKey: UUID()).getUrlRequest()
        precondition(delete.httpMethod == "DELETE" && delete.httpBody == nil)
        print("PASS: 친구 결과·집계 히트맵 디코딩·공개 조건·페이지 처리·권한 상실·작성자·댓글 중복/길이/실패 재시도·삭제 API 계약")
    }
}
