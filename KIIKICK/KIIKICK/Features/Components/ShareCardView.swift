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
//  히트맵은 AnalysisDetailView에서 "지금 보고 있는 쿼터"를 그대로 넘겨받아 본문과 같은
//  FieldHeatmapView로 그린다. MapKit이 아니라 Canvas라서 ImageRenderer 캡처에도 그대로
//  찍힌다. 운동장이 없거나 경로가 비면 기존 gray850+map 아이콘 placeholder로 돌아간다.
//  히트맵 슬롯(109x72)은 img_field 원본(1536x1024)과 같은 3:2라 꽉 맞는다.
//
//  DESIGN-GAP: 라벨 폰트는 Figma가 Kanit-Medium 8pt인데 프로젝트엔 Kanit-SemiBold만
//  번들돼 있어 그걸로 대체했다.
//

import SwiftUI

struct ShareCardView: View {
    enum Orientation { case vertical, horizontal }

    let keyStats: [AnalysisStat]
    let orientation: Orientation
    /// 공유 버튼을 누른 시점에 보고 있던 쿼터. nil이면 히트맵 자리를 placeholder로 둔다.
    var quarter: AnalysisQuarter? = nil

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
                    heatmap
                        .frame(height: 72)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 32)

            case .horizontal:
                HStack(spacing: 20) {
                    statsColumn
                    heatmap
                        .frame(width: 109, height: 72)
                }
                .padding(32)
            }
        }
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

    @ViewBuilder
    private var heatmap: some View {
        if let quarter, let field = quarter.field, !quarter.points.isEmpty {
            FieldHeatmapView(
                field: field,
                points: quarter.points,
                isAttackDirectionReversed: quarter.isAttackDirectionReversed
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            heatmapPlaceholder
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
