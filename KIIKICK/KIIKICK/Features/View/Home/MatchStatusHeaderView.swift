//
//  MatchStatusHeaderView.swift
//  KIIKICK
//
//  홈 화면 상단 "경기 상태" 배너. 예전에는 이 컴포넌트가 화면 전체를 차지했지만(이슈 #9),
//  이슈 #42부터는 Figma "overall" 프레임 계열의 상단 배너 한 조각일 뿐이고 그 아래에
//  OverallSummaryView(점수/통계)가 이어진다.
//
//  node 241:1504/259:2992/241:1907/241:1583~1584(예전 주석에 있던 ID)는 더 이상 파일에
//  존재하지 않는다 — Figma 쪽에서 재정리된 것으로 보인다. 아래 각 case의 문구는 현재
//  "overall" 프레임들(예: 733:9278=prepared, 733:9566=inProgress, 733:9112=watchDisconnected,
//  733:8987=noRecords)에서 다시 확인한 값이다. `.justFinished`만 이번에 재확인할 대응
//  프레임을 찾지 못해 이전 문구를 그대로 유지했다 — 다음에 Figma를 다시 볼 때 확인할 것.
//

import SwiftUI

struct MatchStatusHeaderView: View {
    let state: HomeMatchState
    let onPrepareMatch: () -> Void
    let onForceEndMatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .idle:
                EmptyView()

            case .watchDisconnected:
                watchInfoRow

            case .noRecords:
                InfoRow(
                    text: "아직 경기 기록이 없어요\n우측 상단의 + 버튼으로 새로운 경기를 준비하세요",
                    font: .body3R
                )

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
    var icon: Image? = nil
    let text: String
    let font: Font
    var alignment: TextAlignment = .leading

    var body: some View {
        Group {
            switch alignment {
            case .center:
                VStack(spacing: 8) {
                    icon?.foregroundStyle(.colorTextPrimary)
                    Text(text)
                        .font(font)
                        .foregroundStyle(.colorTextPrimary)
                        .multilineTextAlignment(.center)
                }
            default :
                HStack(alignment: .top, spacing: 12) {
                    icon?.foregroundStyle(.colorTextPrimary)
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

#Preview("watchDisconnected") {
    MatchStatusHeaderView(state: .watchDisconnected, onPrepareMatch: {}, onForceEndMatch: {})
}

#Preview("noRecords") {
    MatchStatusHeaderView(state: .noRecords, onPrepareMatch: {}, onForceEndMatch: {})
}

#Preview("idle") {
    MatchStatusHeaderView(state: .idle, onPrepareMatch: {}, onForceEndMatch: {})
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
