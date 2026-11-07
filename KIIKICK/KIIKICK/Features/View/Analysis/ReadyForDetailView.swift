//
//  ReadyForDetailView.swift
//  KIIKICK
//
//  Figma node 742:11705 "readyforDetail" (이슈 #43) — 경기 분석을 보기 전에 쿼터별
//  포지션/공격 방향(좌우반전)을 확인·수정하는 확인 화면. CardQuarterView를 쿼터 수만큼
//  반복한다.
//
//  DESIGN-GAP: "분석 보기"를 누르면 실제로 어디(AnalyzingView? AnalysisDetailView
//  직행?)로 넘어가고 수정값을 어떻게 저장하는지는 아직 안 정해졌다 — 워치에서 경기가
//  막 도착했을 때 이 화면으로 들어오는 진입점 자체도 이번 범위 밖(이슈 #43은 "이 화면
//  구현 전에 컴포넌트만 먼저 준비"로 범위가 한정돼 있었다). 그래서 CTA는 아직 아무
//  데도 연결돼 있지 않다.
//

import SwiftUI

struct ReadyForDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let dateAndQuarterText: String
    let quarters: [AnalysisQuarter]

    @State private var positions: [String]
    @State private var flips: [Bool]

    init(dateAndQuarterText: String, quarters: [AnalysisQuarter]) {
        self.dateAndQuarterText = dateAndQuarterText
        self.quarters = quarters
        _positions = State(initialValue: quarters.map(\.position))
        _flips = State(initialValue: quarters.map { _ in false })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(dateAndQuarterText)
                    .font(.head2SB)
                    .foregroundStyle(.colorTextPrimary)

                directionGuide

                ForEach(Array(quarters.enumerated()), id: \.element.id) { index, quarter in
                    CardQuarterView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        position: $positions[index],
                        isFlipped: $flips[index],
                        positionChangeText: positions[index] == quarter.position ? nil : "\(quarter.position) → \(positions[index])"
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("모든 쿼터의 설정을 한 번에 저장합니다.")
                        .font(.caption1M)
                        .foregroundStyle(.colorTextSecondary)
                    CtaView(text: "분석 보기", type: .primary, size: .large) {
                        // TODO: 저장 API/다음 화면 연결은 범위 밖 — 헤더 주석 참고.
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
            ToolbarItem(placement: .principal) {
                Text("분석 준비")
                    .font(.head3B)
                    .foregroundStyle(.colorTextPrimary)
            }
        }
    }

    private var directionGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("공격 방향은 오른쪽으로 맞춰주세요")
                .font(.label1M)
                .foregroundStyle(.colorTextPrimary)
            Text("실제 공격 방향과 다르면 맵을 좌우 반전하세요")
                .font(.body4R)
                .foregroundStyle(.colorTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.colorBackgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ReadyForDetailView(
            dateAndQuarterText: "10월 30일 · 총 3쿼터",
            quarters: [
                AnalysisQuarter(quarterNumber: 1, durationText: "00:00", position: "CM", heatmapPageCount: 1),
                AnalysisQuarter(quarterNumber: 2, durationText: "00:00", position: "CM", heatmapPageCount: 1),
                AnalysisQuarter(quarterNumber: 3, durationText: "00:00", position: "CM", heatmapPageCount: 1),
            ]
        )
    }
}
