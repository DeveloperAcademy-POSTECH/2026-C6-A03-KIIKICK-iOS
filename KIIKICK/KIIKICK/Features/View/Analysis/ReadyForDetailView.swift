//
//  ReadyForDetailView.swift
//  KIIKICK
//
//  Figma node 742:11705 "readyforDetail" (이슈 #43) — 경기 분석을 보기 전에 쿼터별
//  포지션/공격 방향(좌우반전)을 확인·수정하는 확인 화면. CardQuarterView를 쿼터 수만큼
//  반복한다.
//
//  분석 플로우: AnalysisView(목록) → ReadyForDetailView(여기) → AnalyzingView →
//  AnalysisDetailView → TimelineView. 실제 분석 API가 아직 없어서 "분석 보기"를
//  누르면 수정한 포지션/반전 값을 저장하지 않고 AnalyzingView로 그대로 넘어간다 —
//  저장 API 연동은 범위 밖.
//

import SwiftUI

struct ReadyForDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    let entry: AnalysisEntry
    @State private var positions: [String]
    @State private var flips: [Bool]

    private var quarters: [AnalysisQuarter] { entry.detail.quarters }

    init(entry: AnalysisEntry) {
        self.entry = entry
        _positions = State(initialValue: entry.detail.quarters.map(\.position))
        _flips = State(initialValue: entry.detail.quarters.map { _ in false })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(entry.dateAndQuarter)
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
                        router.paths[.analysis, default: .init()].append(AnalysisRoute.analyzing(entry))
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
        ReadyForDetailView(entry: AnalysisMockData.entries[0])
    }
    .environment(AppRouter())
}
