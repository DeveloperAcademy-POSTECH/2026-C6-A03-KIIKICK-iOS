//
//  OverallSummaryView.swift
//  KIIKICK
//
//  Figma "overall" 프레임 계열 상단의 Overall 점수 + 링 + 통계 카드 3개 블록.
//  점수/증감은 OverallScoreView(Components/OverallScoreView.swift, node 732:6852
//  "OverallScore")로, 링은 ProfileRingView(node 732:6891 "ProfileRing")로, 통계 카드는
//  CardStatView(node 732:6866 "card_stat")로 분리했다 — 전부 get_design_context로 받은
//  실제 Figma 컴포넌트다.
//
//  Overall 점수/증감(delta)은 서버 API 연동 전이라 항상 OverallStat.empty다
//  (OverallStat.swift 참고) — "00"이 표시된다. 100 이상일 때 Overdrive로 바뀌는 연출은
//  만들어 뒀지만, 실제 점수가 들어오기 전까지는 확인할 방법이 없다.
//

import SwiftUI

struct OverallSummaryView: View {
    let stat: OverallStat
    let matchCount: Int
    let totalDistanceKm: Double
    let avgCalories: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 36) {
                OverallScoreView(score: stat.score, delta: stat.delta)
                ProfileRingView(isOverdrive: (stat.score ?? 0) >= 100, size: 190)
            }
            
            HStack(spacing: 8) {
                CardStatView(label: "총 경기 수", value: "\(matchCount)", unit: "회")
                CardStatView(label: "총 이동거리", value: String(format: "%.1f", totalDistanceKm), unit: "km")
                CardStatView(label: "평균 소모 칼로리", value: "\(avgCalories)", unit: "kcal")
            }
        }
    }
}

#Preview("empty") {
    OverallSummaryView(stat: .empty, matchCount: 0, totalDistanceKm: 0, avgCalories: 0)
        .padding()
        .background(Color.gray950)
}

#Preview("mint (<100)") {
    OverallSummaryView(stat: OverallStat(score: 90, delta: 2), matchCount: 4, totalDistanceKm: 12.4, avgCalories: 420)
        .padding()
        .background(Color.gray950)
}

#Preview("lime (>=100)") {
    OverallSummaryView(stat: OverallStat(score: 120, delta: 2), matchCount: 9, totalDistanceKm: 28.1, avgCalories: 510)
        .padding()
        .background(Color.gray950)
}
