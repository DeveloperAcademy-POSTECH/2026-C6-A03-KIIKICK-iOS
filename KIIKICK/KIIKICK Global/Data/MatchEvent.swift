//
//  MatchEvent.swift
//  KIIKICK Global
//
//  워치에서 골/어시스트 스테퍼를 누른 시각과 가장 최근 GPS 위치를 기록한다. TrackPoint와 별도로
//  두는 이유는 TrackPoint는 위치 수집 주기(1m 간격)마다 쌓이는 경로 포인트고, 이건
//  득점/어시스트처럼 의미 있는 이벤트가 발생한 시점 하나만 가리키기 때문이다.
//

import SwiftUI

enum MatchEventType: String, Codable, Hashable {
    case goal, assist
    
    var name: String {
        switch self {
        case .goal:
            "골"
        case .assist:
            "어시스트"
        }
    }
    
    var image: Image {
        switch self {
        case .goal:
            Image("img_goal")
        case .assist:
            Image("img_assist")
        }
    }
}

struct MatchEvent: Codable {
    let type: MatchEventType
    let location: TrackPoint
}
