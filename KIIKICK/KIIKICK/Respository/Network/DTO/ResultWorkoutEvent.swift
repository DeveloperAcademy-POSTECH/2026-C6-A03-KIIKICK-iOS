/// 업로드 이벤트의 좌표·시각은 친구에게 받은 GPS 경로로 간주하지 않는다. 개수만 집계한다.
struct ResultWorkoutEvent: Decodable {
    let type: String
}
