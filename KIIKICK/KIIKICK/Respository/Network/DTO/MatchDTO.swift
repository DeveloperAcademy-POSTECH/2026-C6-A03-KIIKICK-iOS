//
//  MatchDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/setup.md(SET-06~11), docs/api/gameplay.md(GAME-01,02,08,11,12),
//  docs/api/schemas.md의 Match 기준.
//

import Foundation

enum MatchStatus: String, Codable {
    case draft = "DRAFT"
    case ready = "READY"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
}

struct VenueSnapshot: Codable {
    let name: String
    let address: String?
}

struct MatchResponse: Decodable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let title: String?
    let venueId: UUID?
    let venueSnapshot: VenueSnapshot?
    let scheduledAt: Date?
    let status: MatchStatus
    let startedAt: Date?
    let endedAt: Date?
    let version: Int
    let createdAt: Date
    let updatedAt: Date
}

struct MatchCreateRequest: Encodable {
    let title: String?
    let venueId: UUID?
    let venueSnapshot: VenueSnapshot?
    let scheduledAt: String?
}

struct MatchUpdateRequest: Encodable {
    let title: String?
    let venueId: UUID?
    let venueSnapshot: VenueSnapshot?
    let scheduledAt: String?
}

// Requestable.toDictionary()는 평범한 JSONEncoder를 쓰므로 Date를 그대로 넣으면
// 숫자(timeIntervalSinceReferenceDate)로 직렬화된다. 백엔드는 +09:00 오프셋을 포함한
// RFC3339 서울 시각 문자열을 기대하므로, 요청 바디에서는 Date를 이 포맷터로 미리
// 문자열로 바꿔 보낸다.
func rfc3339SeoulString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    return formatter.string(from: date)
}
