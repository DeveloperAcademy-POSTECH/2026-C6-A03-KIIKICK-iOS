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
//  점수와 링은 같은 누적 계산 결과를 사용하며, 100점 이상은 Overdrive로 표시한다.
//

import SwiftUI

struct OverallSummaryView: View {
    let stat: OverallStat
    let matchCount: Int
    let totalDistanceKm: Double
    let avgCalories: Int
    
    var body: some View {
        VStack(spacing: 32) {
            HStack(alignment: .center, spacing: 36) {
                OverallScoreView(score: stat.score, delta: stat.delta)
                ProfileRingView(score: stat.score ?? 0, size: 190)
            }
            
            HStack(spacing: 12) {
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

#Preview("20점 · 증가") {
    OverallSummaryView(stat: OverallStat(score: 20, delta: 5), matchCount: 1, totalDistanceKm: 2.1, avgCalories: 180)
        .padding()
        .background(Color.gray950)
}

#Preview("20점 · 감소") {
    OverallSummaryView(stat: OverallStat(score: 20, delta: -5), matchCount: 1, totalDistanceKm: 2.1, avgCalories: 180)
        .padding()
        .background(Color.gray950)
}

#Preview("20점 · 변동 없음") {
    OverallSummaryView(stat: OverallStat(score: 20, delta: 0), matchCount: 1, totalDistanceKm: 2.1, avgCalories: 180)
        .padding()
        .background(Color.gray950)
}

#Preview("100점 · Overdrive 경계") {
    OverallSummaryView(stat: OverallStat(score: 100, delta: 3), matchCount: 6, totalDistanceKm: 18.7, avgCalories: 460)
        .padding()
        .background(Color.gray950)
}

#Preview("120점 · Overdrive") {
    OverallSummaryView(stat: OverallStat(score: 120, delta: -4), matchCount: 9, totalDistanceKm: 28.1, avgCalories: 510)
        .padding()
        .background(Color.gray950)
}
