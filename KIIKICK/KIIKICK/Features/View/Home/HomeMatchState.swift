//
//  HomeMatchState.swift
//  KIIKICK
//
//  Figma node 120:12 "home" 4가지 상태(경기 생성 전/후/중/후)를 나타낸다.
//

import Foundation

enum HomeMatchState: Equatable {
    case readyToPrepare
    case prepared(fieldName: String)
    case inProgress
    case justFinished(record: WorkoutRecord)
}
