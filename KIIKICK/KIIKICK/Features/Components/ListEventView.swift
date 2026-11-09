//
//  ListEventView.swift
//  KIIKICK
//
//  Figma "ListEvent" (node 511:4864/4865, TimelineView 안) — 골/어시스트 타임라인 행.
//  아이콘(ic_goal/ic_assist, 28×28) + "Goal N"/"Assist N" + 시각, 텍스트는 label2_sb
//  (14pt SemiBold) + color-text-primary.
//
//  ic_goal/ic_assist는 Asset Catalog에 template-rendering-intent가 박혀 있어서(다른
//  단색 아이콘들과 같은 카탈로그 설정), .foregroundStyle을 안 줘도 시스템이 기본으로
//  단색 실루콜 템플릿으로 그려버린다 — 정작 이 두 에셋은 어두운 원 배경 + 흰색 공
//  패턴의 2톤 디자인이 이미 들어있는 전체 컬러 그래픽이다. .renderingMode(.original)로
//  카탈로그의 template 설정을 무시하고 원본 색 그대로 그려야 제대로 보인다(실제로
//  한 번 겪은 버그 — .foregroundStyle만 뺐을 땐 여전히 단색 원으로 보였다).
//

import SwiftUI

struct ListEventView: View {
    let type: TimelineEventType
    let number: Int
    let timeText: String

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(type.iconName)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 28, height: 28)
                Text("\(type.label) \(number)")
                    .font(.label2SB)
                    .foregroundStyle(.colorTextPrimary)
            }
            Spacer()
            Text(timeText)
                .font(.label2SB)
                .foregroundStyle(.colorTextPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ListEventView(type: .goal, number: 1, timeText: "00:00")
        ListEventView(type: .assist, number: 1, timeText: "00:00")
    }
    .padding()
    .background(Color.gray950)
}
