import Foundation

/// 계정별 목업 경기 데이터에 사용할 포지션.
/// 실제 선수 기록이 아니라 포지션별 움직임을 표현하는 개발용 목업 설정이다.
enum MockHeatmapPosition: String, CaseIterable, Codable, Hashable, Identifiable {
    case attacker = "son-heung-min"
    case midfielder = "lee-kang-in"
    case defender = "kim-min-jae"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .attacker: "공격수"
        case .midfielder: "미드필더"
        case .defender: "수비수"
        }
    }

    var profileDisplayName: String {
        switch self {
        case .attacker: "손흥민 스타일"
        case .midfielder: "이강인 스타일"
        case .defender: "김민재 스타일"
        }
    }

    var description: String {
        switch self {
        case .attacker: "전방 침투와 측면 스프린트 중심"
        case .midfielder: "중앙·하프스페이스 연결 중심"
        case .defender: "자기 진영 중앙 수비 중심"
        }
    }

    var symbolName: String {
        switch self {
        case .attacker: "figure.soccer"
        case .midfielder: "point.3.connected.trianglepath.dotted"
        case .defender: "shield.fill"
        }
    }

    var workoutPosition: Position {
        switch self {
        case .attacker: .st
        case .midfielder: .cm
        case .defender: .cb
        }
    }
}
