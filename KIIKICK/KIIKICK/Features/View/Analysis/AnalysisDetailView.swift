//
//  AnalysisDetailView.swift
//  KIIKICK
//
//  Figma node 367:1711 "detail" / 371:2951 "comment" (이슈 #17) — 둘은 같은 화면에서
//  세그먼트 컨트롤(분석/댓글)로 내용만 바뀌는 구조라 한 파일에서 같이 구현한다.
//

import SwiftUI

enum AnalysisSegment: String, CaseIterable, Hashable {
    case analysis = "분석"
    case comments = "댓글"
}

struct AnalysisDetailView: View {
    let entry: AnalysisEntry

    @State private var segment: AnalysisSegment = .analysis
    @State private var selectedQuarterIndex = 0
    @State private var comments: [Comment] = CommentMockData.threads
    @State private var commentText = ""
    @State private var pushedFriendsPlayedTogether = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                ForEach(AnalysisSegment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            switch segment {
            case .analysis:
                AnalysisTabContent(detail: entry.detail, selectedQuarterIndex: $selectedQuarterIndex)
            case .comments:
                CommentsTabContent(
                    comments: $comments,
                    commentText: $commentText,
                    friendsCount: AnalysisMockData.friendsPlayedTogether.count,
                    onShowFriends: { pushedFriendsPlayedTogether = true }
                )
            }
        }
        .background(Color.gray950)
        .navigationTitle(entry.detail.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("공유하기", action: {})
                    Button("삭제하기", role: .destructive, action: {})
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.gray50)
                }
            }
        }
        .navigationDestination(isPresented: $pushedFriendsPlayedTogether) {
            FriendsPlayedTogetherView(friends: AnalysisMockData.friendsPlayedTogether)
        }
    }
}

private struct AnalysisTabContent: View {
    let detail: AnalysisDetail
    @Binding var selectedQuarterIndex: Int

    private var currentQuarter: AnalysisQuarter? {
        guard detail.quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return detail.quarters[selectedQuarterIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let quarter = currentQuarter {
                    quarterPager(quarter)
                    positionRow(quarter)
                    heatmapCarousel(quarter)
                }

                Text("히트맵과 포지션이 정확한지 확인해주세요")
                    .font(.caption1M)
                    .foregroundStyle(.gray500)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {}) {
                    Text("내 플레이 공유하기")
                        .font(.title2SB)
                        .gradientForeground()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mint500, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                keyStatsSection
                goalAssistSection

                ForEach(detail.sections) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    private func quarterPager(_ quarter: AnalysisQuarter) -> some View {
        HStack {
            Button {
                selectedQuarterIndex = max(0, selectedQuarterIndex - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(selectedQuarterIndex == 0 ? .gray700 : .gray50)
            }
            .buttonStyle(.plain)
            .disabled(selectedQuarterIndex == 0)

            Spacer()

            Text("\(quarter.quarterNumber) 쿼터 \(quarter.durationText)")
                .font(.title1SB)
                .foregroundStyle(.gray50)

            Spacer()

            Button {
                selectedQuarterIndex = min(detail.quarters.count - 1, selectedQuarterIndex + 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(selectedQuarterIndex == detail.quarters.count - 1 ? .gray700 : .gray50)
            }
            .buttonStyle(.plain)
            .disabled(selectedQuarterIndex == detail.quarters.count - 1)
        }
    }

    private func positionRow(_ quarter: AnalysisQuarter) -> some View {
        HStack {
            Text(quarter.position)
                .font(.label2SB)
                .foregroundStyle(.gray50)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray850, in: Capsule())

            Spacer()

            Button(action: {}) {
                Text("타임스탬프 보러가기")
                    .font(.label3M)
                    .foregroundStyle(.mint500)
            }
            .buttonStyle(.plain)
        }
    }

    // DESIGN-GAP: 실제 히트맵 이미지가 없어서 페이지 수만큼 placeholder 사각형을 넘긴다.
    private func heatmapCarousel(_ quarter: AnalysisQuarter) -> some View {
        TabView {
            ForEach(0..<quarter.heatmapPageCount, id: \.self) { page in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray850)
                    .overlay(
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray500)
                    )
                    .tag(page)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 220)
    }

    private var keyStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Stats")
                .font(.title2SB)
                .gradientForeground()

            HStack(spacing: 28) {
                ForEach(detail.keyStats, id: \.label) { stat in
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
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var goalAssistSection: some View {
        HStack(spacing: 24) {
            statBadge(icon: "soccerball.inverse", label: "골", count: detail.goalCount)
            statBadge(icon: "shoe.running.and.shadow.fill", label: "어시스트", count: detail.assistCount)
        }
        .frame(maxWidth: .infinity)
    }

    private func statBadge(icon: String, label: String, count: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.mint500)
            Text("\(count)")
                .font(.display3SB)
                .foregroundStyle(.gray50)
            Text(label)
                .font(.caption1M)
                .foregroundStyle(.gray400)
        }
        .frame(width: 80, height: 80)
        .background(Color.gray900, in: Circle())
    }

    private func sectionView(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.title2SB)
                .gradientForeground()

            VStack(spacing: 0) {
                ForEach(section.rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.body4R)
                            .foregroundStyle(.gray400)
                        Spacer()
                        Text(row.value)
                            .font(.body1M)
                            .foregroundStyle(.gray50)
                    }
                    .padding(.vertical, 12)

                    if row != section.rows.last {
                        Rectangle()
                            .fill(Color.gray850)
                            .frame(height: 1)
                    }
                }
            }
            .padding(16)
            .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct CommentsTabContent: View {
    @Binding var comments: [Comment]
    @Binding var commentText: String
    let friendsCount: Int
    var onShowFriends: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button(action: onShowFriends) {
                        HStack {
                            Text("함께 뛴 친구 \(friendsCount)명")
                                .font(.label2SB)
                                .foregroundStyle(.gray50)
                            Spacer()
                            Image("ic_arrow")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        .padding(16)
                        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    ForEach(comments) { comment in
                        CommentThreadView(comment: comment)
                    }
                }
                .padding(16)
            }

            CommentComposerView(text: $commentText) {
                let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                comments.append(Comment(authorNickname: "나", content: trimmed, timestamp: "방금"))
                commentText = ""
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisDetailView(entry: AnalysisMockData.entries[0])
    }
}
