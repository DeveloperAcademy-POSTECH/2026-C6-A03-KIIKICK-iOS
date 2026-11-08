import Foundation

@main
struct QueryModelsTests {
    @MainActor
    static func main() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = Date(timeIntervalSince1970: 1_800_000_000)
        let yesterday = today.addingTimeInterval(-86_400)
        let pending = NotificationItem(date: today, kind: .friendRequest(status: .pending, nickname: "민수"))
        let comment = NotificationItem(date: yesterday, kind: .comment(nickname: "준", preview: "hello"))
        let model = NotificationListModel()
        model.replace([comment, pending], calendar: calendar)
        precondition(model.sections(for: .all).count == 2)
        precondition(model.sections(for: .all).first?.rows.first?.id == pending.id)
        let row = model.sections(for: .friendRequest)[0].rows[0]
        model.updateStatus(id: pending.id, to: .accepted)
        precondition(row.item.kind == .friendRequest(status: .accepted, nickname: "민수"))
        precondition(model.sections(for: .all).first?.rows.first === row)
        precondition(model.sections(for: .comment)[0].rows[0].id == comment.id)
        model.updateStatus(id: UUID(), to: .rejected)
        model.replace([comment], calendar: calendar)
        precondition(model.sections(for: .friendRequest).isEmpty)
        model.updateStatus(id: pending.id, to: .rejected)
        precondition(model.sections(for: .all).flatMap(\.rows).count == 1)
        model.replace([pending, comment], calendar: calendar)
        calendar.timeZone = TimeZone(secondsFromGMT: 32_400)!
        model.regroup(calendar: calendar)
        precondition(model.sections(for: .all).first?.id == calendar.startOfDay(for: today))

        let search = FriendSearchModel()
        let users = [UserProfile(nickname: "민수", status: .none), UserProfile(nickname: "Alpha", status: .friend)]
        await search.search(FriendSearchRequest(query: "", users: users))
        precondition(search.results.isEmpty && !search.isSearching)
        await search.search(FriendSearchRequest(query: "ALP", users: users))
        precondition(search.results.map(\.nickname) == ["Alpha"])
        let old = Task { await search.search(FriendSearchRequest(query: "민", users: users)) }
        try await Task.sleep(for: .milliseconds(20))
        old.cancel()
        await search.search(FriendSearchRequest(query: "수", users: users))
        await old.value
        precondition(search.results.map(\.nickname) == ["민수"])
        let changed = [UserProfile(nickname: "수정", status: .none)]
        await search.search(FriendSearchRequest(query: "수", users: changed))
        precondition(search.results.map(\.nickname) == ["수정"])
        print("Query model checks passed: sections, filters, ID updates, replacement, time zone, search and cancellation")
    }
}
