//
//  MatchStatusHeaderView.swift
//  KIIKICK
//
//  홈 화면 상단 "경기 상태" 뷰. Figma node 241:1504(경기 생성 전) / 259:2992(경기 생성 후) /
//  241:1907(경기중) / 241:1583~1584(경기 후) 4가지 상태를 하나의 컴포넌트로 묶었다.
//

import SwiftUI

struct MatchStatusHeaderView: View {
    let state: HomeMatchState
    let onPrepareMatch: () -> Void
    let onForceEndMatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .readyToPrepare:
                watchInfoRow
                CtaView(text: "경기 준비하기", type: .primary, action: onPrepareMatch)

            case .prepared(let fieldName):
                CardInfoView(
                    title: fieldName,
                    message: "경기가 준비되었어요. Apple Watch에서 시작해주세요."
                )

            case .inProgress:
                InfoRow(
                    // DESIGN-GAP: 실제 ic/info 에셋 미다운로드, SF Symbol로 대체.
                    icon: Image(systemName: "info.circle"),
                    text: "아직 경기를 진행 중이에요!\n이번 경기 분석을 보려면 Apple Watch에서\n경기를 종료해주세요",
                    font: .body3R,
                    alignment: .center
                )
                Button(action: onForceEndMatch) {
                    Text("강제로 경기 종료하기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.actionDestructive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

            case .justFinished(let record):
                watchInfoRow
                CtaView(text: "경기 준비하기", type: .primary, action: onPrepareMatch)
                NavigationLink(value: record) {
                    NaviRowView(
                        icon: Image("ic_new"),
                        text: "새로운 분석지가 도착했어요! 확인해보세요"
                    )
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
        .padding(.horizontal, 24)
        .background(.colorBackgroundSecondary)
    }
    
    private var watchInfoRow: some View {
        InfoRow(
            icon: Image(systemName: "applewatch"),
            text: "경기 기록은 Apple Watch에서 시작할 수 있어요. 연결 상태를 확인해주세요.",
            font: .body4R
        )
    }
}

private struct InfoRow: View {
    let icon: Image
    let text: String
    let font: Font
    var alignment: TextAlignment = .leading

    var body: some View {
        Group {
            switch alignment {
            case .center:
                VStack(spacing: 8) {
                    icon
                        .foregroundStyle(.colorTextPrimary)
                    Text(text)
                        .font(font)
                        .foregroundStyle(.colorTextPrimary)
                }
            default :
                HStack(alignment: .top, spacing: 12) {
                    icon
                        .foregroundStyle(.colorTextPrimary)
                    Text(text)
                        .font(font)
                        .foregroundStyle(.colorTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("readyToPrepare") {
    MatchStatusHeaderView(state: .readyToPrepare, onPrepareMatch: {}, onForceEndMatch: {})
}

#Preview("prepared") {
    MatchStatusHeaderView(state: .prepared(fieldName: "우리 집 앞 풋살장"), onPrepareMatch: {}, onForceEndMatch: {})
}

#Preview("inProgress") {
    MatchStatusHeaderView(state: .inProgress, onPrepareMatch: {}, onForceEndMatch: {})
}

#if DEBUG
#Preview("justFinished") {
    MatchStatusHeaderView(
        state: .justFinished(record: WorkoutRecord(payload: .fake())),
        onPrepareMatch: {},
        onForceEndMatch: {}
    )
}
#endif
