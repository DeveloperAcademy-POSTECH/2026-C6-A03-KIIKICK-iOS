//
//  AnalysisDetailView.swift
//  KIIKICK
//
//  Figma node 367:1711 "detail" / 735:11387 "detail"(이슈 #43 갱신본) — 이슈 #43에서
//  "분석"/"댓글" 세그먼트 컨트롤을 없애고, 댓글은 화면 아래 항상 떠 있는 바텀시트로
//  바꿨다(접힌 상태에서도 "댓글 N" 헤더가 보이고, 끌어올리면 전체 목록이 보임).
//  히트맵 위에는 "타임라인 보기" 버튼을 추가해 TimelineView로 넘어간다.
//  node 735:11387의 toolbar는 뒤로가기 + 제목 + 우측 상단 공유 버튼 하나뿐이라
//  기존 ellipsis 메뉴(공유하기/삭제하기)를 없애고 공유 버튼만 남겼다. "삭제하기"는
//  Figma에서도 툴바가 아니라 본문 하단에 별도 버튼으로 있어서 그 자리로 옮겼다.
//

import SwiftUI

struct AnalysisDetailView: View {
    let entry: AnalysisEntry

    @State private var selectedQuarterIndex = 0
    @State private var comments: [Comment] = CommentMockData.threads
    @State private var commentText = ""
    @State private var pushedFriendsPlayedTogether = false
    @State private var pushedTimeline = false
    @State private var commentSheetDetent: PresentationDetent = .height(140)

    private var currentQuarter: AnalysisQuarter? {
        guard entry.detail.quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return entry.detail.quarters[selectedQuarterIndex]
    }

    var body: some View {
        AnalysisTabContent(
            detail: entry.detail,
            selectedQuarterIndex: $selectedQuarterIndex,
            friendsCount: AnalysisMockData.friendsPlayedTogether.count,
            onShowFriends: { pushedFriendsPlayedTogether = true },
            onShowTimeline: { pushedTimeline = true }
        )
        .background(Color.gray950)
        .navigationTitle(entry.detail.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.gray50)
                }
            }
        }
        .navigationDestination(isPresented: $pushedFriendsPlayedTogether) {
            FriendsPlayedTogetherView(friends: AnalysisMockData.friendsPlayedTogether)
        }
        .navigationDestination(isPresented: $pushedTimeline) {
            if let currentQuarter {
                TimelineView(dateTitle: entry.detail.title, quarter: currentQuarter)
            }
        }
        // 댓글은 세그먼트 전환이 아니라, 화면 아래 항상 떠 있는 바텀시트로 보여준다
        // (Figma "sheet/collapsed", node 735:11489) — 접힌 상태에서도 "댓글 N" 헤더가
        // 보이고 끌어올리면 전체 목록이 보인다. 닫을 수 없는 permanent 시트라
        // isPresented를 상수 true로 고정했다.
        .sheet(isPresented: .constant(true)) {
            CommentsSheetContent(
                comments: $comments,
                commentText: $commentText,
                isExpanded: commentSheetDetent == .large
            )
            .presentationDetents([.height(70), .large], selection: $commentSheetDetent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(Color.gray900)
            .interactiveDismissDisabled()
        }
    }
}

private struct AnalysisTabContent: View {
    let detail: AnalysisDetail
    @Binding var selectedQuarterIndex: Int
    let friendsCount: Int
    var onShowFriends: () -> Void
    var onShowTimeline: () -> Void

    private var currentQuarter: AnalysisQuarter? {
        guard detail.quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return detail.quarters[selectedQuarterIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button(action: onShowFriends) {
                    HStack(spacing: 4) {
                        Text("함께 뛴 친구 \(friendsCount)명")
                            .font(.body4R)
                            .foregroundStyle(.colorTextPrimary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.mint500)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                if let quarter = currentQuarter {
                    QuarterSelectorView(
                        quarterNumber: quarter.quarterNumber,
                        durationText: quarter.durationText,
                        canGoPrevious: selectedQuarterIndex > 0,
                        canGoNext: selectedQuarterIndex < detail.quarters.count - 1,
                        onPrevious: { selectedQuarterIndex = max(0, selectedQuarterIndex - 1) },
                        onNext: { selectedQuarterIndex = min(detail.quarters.count - 1, selectedQuarterIndex + 1) }
                    )
                    .frame(maxWidth: .infinity)

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

                CtaView(text: "삭제하기", type: .destructive, size: .small) {}

                // 바텀시트가 접혀 있어도 마지막 섹션이 가리지 않게 여유 공간을 둔다.
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
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
        .overlay(alignment: .bottomTrailing) {
            Button(action: onShowTimeline) {
                HStack(spacing: 0) {
                    Text("타임라인 보기")
                        .font(.caption1M)
                        .foregroundStyle(.colorTextPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.colorTextPrimary)
                }
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .background(Color.colorSurfacePrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(16)
        }
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

private struct CommentsSheetContent: View {
    @Binding var comments: [Comment]
    @Binding var commentText: String
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            VStack { }.frame(height: 4)
            Text("댓글 \(comments.count)")
                .font(.title3M)
                .foregroundStyle(.colorTextPrimary)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(comments) { comment in
                        CommentThreadView(comment: comment)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // 시트가 접혀 있을 땐("댓글 N" 헤더만 보이는 상태) 입력창을 숨긴다 —
            // 끝까지 끌어올려 .large 상태가 됐을 때만 댓글을 쓸 수 있게 한다.
            if isExpanded {
                CommentComposerView(text: $commentText) {
                    let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    comments.append(Comment(authorNickname: "나", content: trimmed, timestamp: "방금"))
                    commentText = ""
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalysisDetailView(entry: AnalysisMockData.entries[0])
    }
}
