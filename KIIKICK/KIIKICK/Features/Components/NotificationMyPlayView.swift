//
//  NotificationMyPlayView.swift
//  KIIKICK
//
//  Figma node 747:5385 "notification_myPlay" — 경기 분석 결과가 준비됐을 때 뜨는 알림 행.
//  annotation: "처음 진입 시 분석 준비 페이지로 이동(포지션/공격 방향 설정), 이후엔 분석
//  결과 페이지로 이동" — ReadyForDetailView/AnalyzingView(이슈 #43)가 이 브랜치엔 아직
//  없어서 지금은 항상 AnalysisDetailView(결과 화면)로 바로 보낸다. #43이 머지되면 첫
//  진입 분기를 추가할 것 — DESIGN-GAP.
//

import SwiftUI

struct NotificationMyPlayView: View {
    let matchDate: Date
    var onTap: () -> Void = {}

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: matchDate)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // ic_new는 라임 원 배경 + 어두운 "new" 글자가 박힌 2톤 에셋인데 카탈로그엔
                // template-rendering-intent가 걸려 있어서(이번 세션에서 ic_goal/ic_assist와
                // 같은 패턴) .renderingMode(.original)이 없으면 단색 실루엣으로 깨진다.
                Image("ic_new")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 28, height: 28)

                Text("\(dateText) 경기 분석 결과가 도착했어요!\n내 플레이를 확인해보세요")
                    .font(.body4R)
                    .foregroundStyle(.colorTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image("ic_arrow")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.colorTextPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotificationMyPlayView(matchDate: Date())
        .padding()
        .background(Color.gray950)
}
