//
//  OverallStat.swift
//  KIIKICK
//
//  OverallCalculator로 계산한 누적 점수와, 최신 쿼터가 추가되기 전 대비 증감을 표시한다.
//

import Foundation

struct OverallStat: Equatable {
    /// nil이면 산정 가능한 운동 기록이 없음(00으로 표시).
    var score: Int?
    /// 최신 쿼터를 제외한 누적 점수 대비 증감. 첫 쿼터에는 표시하지 않는다.
    var delta: Int?

    static let empty = OverallStat(score: nil, delta: nil)
}
