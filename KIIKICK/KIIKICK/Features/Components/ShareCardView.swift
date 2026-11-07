//
//  ShareCardView.swift
//  KIIKICK
//
//  Figma node 750:5601(세로형)/750:5653(가로형) "instagram" — ShareImageView가 이미지로
//  내보내는 카드 자체. annotation에 "투명 배경 .png 형태로 다운로드"라고 돼 있어서
//  카드 자체엔 배경을 안 칠한다(ShareImageView 쪽 화면 배경이 어차피 어두워서
//  화면에서 보일 땐 차이가 없고, ImageRenderer로 내보낼 때만 알파 채널이 살아있다).
//
//  카드 폭은 Figma 실측값(301/302)을 그대로 박지 않고 콘텐츠에 맞춰 hug한다 —
//  고정폭(109)에 "22.6 km/h" 같은 값을 넣으면 이 프로젝트에 번들된 Kanit-SemiBold의
//  실제 글자폭이 Figma가 가정한 폭보다 넓어서 줄바꿈 + 세로로 고정해둔 높이 때문에
//  "22.6 km/..."처럼 말줄임표로 잘렸다 — 값 Text에 .fixedSize()를 줘서 항상 한 줄
//  그대로 그리고, 그 폭에 맞춰 카드 전체가 커지도록 바꿨다.
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
                        .frame(height: 72)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)

            case .horizontal:
                HStack(spacing: 20) {
                    statsColumn
                    heatmapPlaceholder
                        .frame(width: 109, height: 72)
                }
                .padding(32)
            }
        }
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
                        .fixedSize()
                    Text("\(stat.value) \(stat.unit)")
                        .font(.display3SB)
                        .foregroundStyle(.colorTextPrimary)
                        .fixedSize()
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
