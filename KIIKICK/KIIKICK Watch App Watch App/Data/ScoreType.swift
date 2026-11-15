//
//  ScoreType.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/15/26.
//

import WorkoutKit
import SwiftUI

enum ScoreType: String {
    case goal, assist

    /// 득점과 어시스트를 화면을 보지 않고도 구분할 수 있는 기본 햅틱.
    var hapticType: WKHapticType {
        switch self {
        case .goal: .success
        case .assist: .directionUp
        }
    }

    var icon: Image {
        switch self {
        case .goal:
            Image(systemName: "soccerball.inverse")
        case .assist:
            // shoe.running.and.shadow.fill은 SF Symbols 2026(watchOS 27.0) 심볼이라
            // 배포 타깃(watchOS 10.6)에서는 런타임에 없어 빈 뷰로 그려졌다 — 같은 모양을
            // 번들 에셋으로 넣어 쓴다. 골(soccerball.inverse)은 2022 심볼이라 그대로 둔다.
            Image("ic_assist_shoe")
        }
    }
}
