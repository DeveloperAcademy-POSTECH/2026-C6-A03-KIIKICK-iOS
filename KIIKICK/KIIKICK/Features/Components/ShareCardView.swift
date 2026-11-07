//
//  ShareCardView.swift
//  KIIKICK
//
//  Figma node 750:5601(세로형)/750:5653(가로형) "instagram" — ShareImageView가 이미지로
//  내보내는 카드 자체. 치수는 get_metadata로 실측한 값 그대로(세로 301×415, 가로
//  302×415, 히트맵 109×72) — 두 레이아웃 모두 히트맵 폭은 109로 고정이다(가로형도
//  Figma 레이어 자체가 flex-grow가 아니라 109 고정폭으로 측정됨).
//
//  DESIGN-GAP: 실제 히트맵 이미지가 없어서 다른 화면과 같은 gray850+map 아이콘
//  placeholder를 쓴다. 라벨 폰트는 Figma가 Kanit-Medium 8pt인데 프로젝트엔
//  Kanit-SemiBold만 번들돼 있어 그걸로 대체했다.
//

import SwiftUI

struct ShareCardView: View {
    enum Orientation { case vertical, horizontal }

    let keyStats: [AnalysisStat]
    let orientation: Orientation

    private static let englishLabels: [String: String] = [
        "최고속도": "Top Speed",
        "이동거리": "Distance",
        "소모칼로리": "Calories Burned",
    ]

    var body: some View {
        Group {
            switch orientation {
            case .vertical:
                VStack(spacing: 20) {
                    statsColumn
                    heatmapPlaceholder
                        .frame(width: 109, height: 72)
                }
                .padding(.horizontal, 96)
                .padding(.vertical, 74)
                .frame(width: 301, height: 415)

            case .horizontal:
                HStack(spacing: 20) {
                    statsColumn
                    heatmapPlaceholder
                        .frame(width: 109, height: 72)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 120)
                .frame(width: 302, height: 415)
            }
        }
        .background(Color.gray950)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray700, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statsColumn: some View {
        VStack(spacing: 20) {
            ForEach(keyStats, id: \.label) { stat in
                VStack(spacing: 6) {
                    Text(Self.englishLabels[stat.label] ?? stat.label)
                        .font(.custom("Kanit-SemiBold", size: 8))
                        .foregroundStyle(.colorTextPrimary)
                    Text("\(stat.value) \(stat.unit)")
                        .font(.display3SB)
                        .foregroundStyle(.colorTextPrimary)
                        .frame(height: 29)
                }
            }
        }
    }

    private var heatmapPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray850)
            .overlay(
                Image(systemName: "map")
                    .font(.system(size: 20))
                    .foregroundStyle(.gray500)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        ShareCardView(
            keyStats: [
                AnalysisStat(label: "최고속도", value: "22.6", unit: "km/h"),
                AnalysisStat(label: "이동거리", value: "2.48", unit: "km"),
                AnalysisStat(label: "소모칼로리", value: "245", unit: "kcal"),
            ],
            orientation: .vertical
        )
        ShareCardView(
            keyStats: [
                AnalysisStat(label: "최고속도", value: "22.6", unit: "km/h"),
                AnalysisStat(label: "이동거리", value: "2.48", unit: "km"),
                AnalysisStat(label: "소모칼로리", value: "245", unit: "kcal"),
            ],
            orientation: .horizontal
        )
    }
    .padding()
    .background(Color.gray950)
}
