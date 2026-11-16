import Foundation

/// 계정별 목업 경기 데이터에 사용할 선수 스타일 테마.
/// 실제 선수 기록이 아니라 포지션별 움직임을 표현하는 개발용 목업 설정이다.
enum MockHeatmapTheme: String, CaseIterable, Codable, Hashable, Identifiable {
    case sonHeungMin = "son-heung-min"
    case leeKangIn = "lee-kang-in"
    case kimMinJae = "kim-min-jae"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sonHeungMin: "손흥민"
        case .leeKangIn: "이강인"
        case .kimMinJae: "김민재"
        }
    }

    var role: String {
        switch self {
        case .sonHeungMin: "전방·측면 공격수"
        case .leeKangIn: "공격형 미드필더"
        case .kimMinJae: "센터백"
        }
    }

    var description: String {
        switch self {
        case .sonHeungMin: "전방 침투와 측면 스프린트 중심"
        case .leeKangIn: "중앙·하프스페이스 연결 중심"
        case .kimMinJae: "자기 진영 중앙 수비 중심"
        }
    }

    var symbolName: String {
        switch self {
        case .sonHeungMin: "figure.soccer"
        case .leeKangIn: "point.3.connected.trianglepath.dotted"
        case .kimMinJae: "shield.fill"
        }
    }
}
