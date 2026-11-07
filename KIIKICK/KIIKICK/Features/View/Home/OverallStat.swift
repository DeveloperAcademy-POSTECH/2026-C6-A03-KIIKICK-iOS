//
//  OverallStat.swift
//  KIIKICK
//
//  "Overall" 점수는 서버 API에서 받아올 예정이고, 계산식 자체도 서버 쪽에서 확정한다
//  (클라이언트에서 직접 계산하지 않는다 — 이슈 #42 논의 결과). 지금은 연결할 API가 아직
//  없어서 이 타입과 `.empty`가 전부다. 실제 Overall API가 나오면:
//  - 이 구조체를 그 응답 DTO로 교체하거나 매핑하고
//  - HomeView의 `overallStat` 상태를 채우는 네트워크 호출(.task 등)을 추가한다.
//

import Foundation

struct OverallStat: Equatable {
    /// nil이면 "아직 값 없음"(00으로 표시). 서버 Overall API 연동 전까지는 기록이 있어도
    /// 항상 nil이다 — 클라이언트가 임의로 숫자를 만들어내지 않는다.
    var score: Int?
    /// 직전 대비 증감. 기준 시점(지난 경기? 지난 주?)도 서버 쪽에서 정의한다.
    var delta: Int?

    static let empty = OverallStat(score: nil, delta: nil)
}
