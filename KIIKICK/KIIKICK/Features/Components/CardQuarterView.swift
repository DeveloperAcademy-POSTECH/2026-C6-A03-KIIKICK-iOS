//
//  CardQuarterView.swift
//  KIIKICK
//
//  Figma "card_quarter" (node 742:11815, "분석 준비" 화면 안의 쿼터별 확인 카드 —
//  이슈 #43: 이 화면 전체를 조립하기 전에 컴포넌트만 먼저 만들어 둔다).
//  bg color-surface-primary(gray850), radius-lg(16), padding 16, 세로 gap 12.
//
//  운동장이 지정된 쿼터는 실제 포인트의 히트맵을 표시한다.
//

import SwiftUI

struct CardQuarterView: View {
    let quarterNumber: Int
    let durationText: String
    var field: Field? = nil
    var points: [TrackPoint] = []
    @Binding var position: String
    @Binding var isFlipped: Bool
    /// 포지션을 수정했을 때만 "CM → LB"처럼 보여준다. 좌우반전은 별도 표기하지 않는다.
    var positionChangeText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(quarterNumber) 쿼터")
                    .font(.title2SB)
                    .foregroundStyle(.colorTextPrimary)
                Spacer()
                Text(durationText)
                    .font(.body4R)
                    .foregroundStyle(.colorTextSecondary)
            }

            HStack(spacing: 4) {
                Text("포지션")
                    .font(.label1M)
                    .foregroundStyle(.colorTextPrimary)
                if let positionChangeText {
                    Text(positionChangeText)
                        .font(.label4SB)
                        .foregroundStyle(.mint500)
                }
                Spacer()
                PositionDropdownView(position: $position)
            }

            TrackingMapPager(field: field, points: points, isAttackDirectionReversed: isFlipped)
                .frame(height: 248)

            HStack {
                Text("공격 방향 →")
                    .font(.label1M)
                    .foregroundStyle(.colorTextSecondary)
                Spacer()
                FlipButtonView(isFlipped: $isFlipped)
            }
        }
        .padding(16)
        .background(Color.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 12) {
        CardQuarterView(quarterNumber: 1, durationText: "00:00", position: .constant("CM"), isFlipped: .constant(false))
        CardQuarterView(
            quarterNumber: 2, durationText: "00:00",
            position: .constant("LB"), isFlipped: .constant(true),
            positionChangeText: "CM → LB"
        )
    }
    .padding()
    .background(Color.gray950)
}
