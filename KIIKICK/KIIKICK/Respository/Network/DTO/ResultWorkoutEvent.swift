/// 업로드 이벤트의 좌표·시각은 친구에게 받은 GPS 경로로 간주하지 않는다. 개수만 집계한다.
struct ResultWorkoutEvent: Decodable {
    let type: String
    let location: Location?

    struct Location: Decodable {
        let latitude: Double
        let longitude: Double
        let timestamp: Double
    }

    private enum CodingKeys: String, CodingKey { case type, location }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        location = try? container.decode(Location.self, forKey: .location)
    }
}
