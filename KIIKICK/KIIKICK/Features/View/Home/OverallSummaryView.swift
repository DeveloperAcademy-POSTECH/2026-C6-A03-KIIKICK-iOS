//
//  OverallSummaryView.swift
//  KIIKICK
//
//  Figma "overall" 프레임 계열 상단의 Overall 점수 + 링 + 통계 카드 3개 블록.
//  링 부분은 ProfileRingView(Components/ProfileRingView.swift, Figma 컴포넌트
//  node 732:6891 "ProfileRing")로 분리했다 — 점수 100 이상이면 Overdrive(라임) 변형을 쓴다.
//
//  "Overall" 라벨/점수 색상·폰트는 get_variable_defs(node 733:9112)로 실측해 교체했다 —
//  라벨은 label/label3_m + color-text-secondary(=gray400, Color.colorTextSecondary),
//  점수는 새로 추가한 display/display0_sb(64pt, TextStyle.swift 참고) + color-text-primary.
//
//  DESIGN-GAP: 카드 radius 등 나머지 토큰은 여전히 스크린샷 기준 근사치다(재검증 안 함).
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
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall")
                        .font(.label3M)
                        .foregroundStyle(.colorTextSecondary)
                    Text(stat.score.map(String.init) ?? "0")
                        .font(.display0SB)
                        .foregroundStyle(.colorTextPrimary)
                    if let delta = stat.delta {
                        Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                            .font(.caption2SB)
                            .foregroundStyle(.gray200)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray850, in: Capsule())
                    }
                }
                Spacer()
                ProfileRingView(isOverdrive: (stat.score ?? 0) >= 100, size: 116)
            }

            HStack(spacing: 8) {
                statCard(label: "총 경기 수", value: "\(matchCount)", unit: "회")
                statCard(label: "총 이동거리", value: String(format: "%.1f", totalDistanceKm), unit: "km")
                statCard(label: "평균 소모 칼로리", value: "\(avgCalories)", unit: "kcal")
            }
        }
    }

    private func statCard(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption1M)
                .foregroundStyle(.gray400)
            Text(value)
                .font(.title1SB)
                .foregroundStyle(.gray50)
            Text(unit)
                .font(.caption2SB)
                .foregroundStyle(.gray500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
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
