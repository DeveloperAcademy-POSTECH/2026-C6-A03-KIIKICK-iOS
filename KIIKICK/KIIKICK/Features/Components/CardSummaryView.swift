//
//  CardSummaryView.swift
//  KIIKICK
//
//  Figma node 331:2728 "card_summary" (Assets&Components 페이지)
//

import SwiftUI

struct CardSummaryView: View {
    struct Stat {
        let label: String
        let value: String
        let unit: String
    }

    let dateAndQuarter: String
    let fieldName: String
    let stats: [Stat]
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateAndQuarter)
                            .font(.caption1M)
                            .foregroundStyle(.gray400)
                        Text(fieldName)
                            .font(.title4SB)
                            .foregroundStyle(.gray50)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("ic_arrow")
                        .resizable()
                        .frame(width: 24, height: 24)
                }

                Rectangle()
                    .fill(Color.gray700)
                    .frame(height: 1)

                HStack(spacing: 28) {
                    ForEach(stats, id: \.label) { stat in
                        VStack(spacing: 12) {
                            Text(stat.label)
                                .font(.title4SB)
                                .foregroundStyle(.gray50)
                            VStack(spacing: 0) {
                                Text(stat.value)
                                    .font(.display3SB)
                                    .foregroundStyle(.gray50)
                                Text(stat.unit)
                                    .font(.body4R)
                                    .foregroundStyle(.gray400)
                            }
                        }
                        .frame(width: 80)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CardSummaryView(
        dateAndQuarter: "00월 00일 • 총 0Q",
        fieldName: "경기장 이름",
        stats: [
            .init(label: "최고속도", value: "22.6", unit: "km/h"),
            .init(label: "이동거리", value: "2.48", unit: "km"),
            .init(label: "소모 칼로리", value: "245", unit: "kcal"),
        ]
    )
    .padding()
    .background(Color.gray950)
}
