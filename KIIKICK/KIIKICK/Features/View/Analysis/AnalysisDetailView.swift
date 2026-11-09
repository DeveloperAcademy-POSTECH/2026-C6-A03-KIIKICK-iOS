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
//  우측 상단 공유 버튼은 ShareImageView(node 750:5505/750:5684, 이미지로 내보내서
//  사진 앱에 저장)로 연결된다. 기존에 본문에 있던 "내 플레이 공유하기" 버튼은
//  삭제하고 그 자리에 "Key Stats" 제목(node 742:11966, 버튼 아님)을 넣었다.
//

import SwiftUI

struct AnalysisDetailView: View {
    let entry: AnalysisEntry

    @State private var selectedQuarterIndex = 0
    // 댓글 API 연동 전이라 항상 빈 목록으로 시작한다(이슈 #42 Mock 데이터 정리 참고).
    @State private var comments: [Comment] = []
    @State private var commentText = ""
    @State private var pushedFriendsPlayedTogether = false
    @State private var pushedTimeline = false
    @State private var pushedShare = false
    @State private var commentSheetDetent: PresentationDetent = .height(140)

    private var currentQuarter: AnalysisQuarter? {
        guard entry.detail.quarters.indices.contains(selectedQuarterIndex) else { return nil }
        return entry.detail.quarters[selectedQuarterIndex]
    }

    var body: some View {
        AnalysisTabContent(
            detail: entry.detail,
            selectedQuarterIndex: $selectedQuarterIndex,
            // 함께 뛴 친구 기록 연동 전이라 항상 0명(이슈 #42 Mock 데이터 정리 참고).
            friendsCount: 0,
            onShowFriends: { pushedFriendsPlayedTogether = true },
            onShowTimeline: { pushedTimeline = true }
        )
        .background(Color.gray950)
        .navigationTitle(entry.detail.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { pushedShare = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.gray50)
                }
            }
        }
        .navigationDestination(isPresented: $pushedFriendsPlayedTogether) {
            FriendsPlayedTogetherView(friends: [])
        }
        .navigationDestination(isPresented: $pushedTimeline) {
            if let currentQuarter {
                TimelineView(dateTitle: entry.detail.title, quarter: currentQuarter)
            }
        }
        .navigationDestination(isPresented: $pushedShare) {
            ShareImageView(keyStats: entry.detail.keyStats)
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

                    if let position = quarter.position {
                        positionRow(position)
                    }
                    heatmapCarousel(quarter)
                }

                Text("히트맵과 포지션이 정확한지 확인해주세요")
                    .font(.caption1M)
                    .foregroundStyle(.gray500)
                    .frame(maxWidth: .infinity, alignment: .center)

                // node 742:11966 — "내 플레이 공유하기" 버튼이 있던 자리에 이제 "Key Stats"
                // 제목이 들어간다(버튼이 아니라 그냥 텍스트). head1B(28pt Bold) + 단색
                // mint500(#00DAC3), gradientForeground 아님.
                Text("Key Stats")
                    .font(.head1B)
                    .foregroundStyle(.mint500)
                    .frame(maxWidth: .infinity, alignment: .center)

                keyStatsSection
                goalAssistSection

                ForEach(detail.sections) { section in
                    sectionView(section)
                }

                CtaView(text: "삭제하기", type: .destructive, size: .large) { }

                // 바텀시트가 접혀 있어도 마지막 섹션이 가리지 않게 여유 공간을 둔다.
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        // 댓글 시트가 .presentationBackgroundInteraction(.enabled)이라 시트 뒤
        // 본문도 탭할 수 있다 — 여기를 눌러도 키보드가 내려가야 한다.
        .dismissKeyboardOnTap()
    }

    private func positionRow(_ position: String) -> some View {
        HStack {
            Text(position)
                .font(.label2SB)
                .foregroundStyle(.gray50)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.gray850, in: Capsule())
            Spacer()
        }
    }

    /// 운동장이 있으면 히트맵/스프린트 두 페이지(WorkoutDetailView와 같은 구성)를, 없으면
    /// 빈 자리를 보여준다.
    private func heatmapCarousel(_ quarter: AnalysisQuarter) -> some View {
        TabView {
            if let field = quarter.field {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray850)
                    .overlay(FieldHeatmapView(field: field, points: quarter.points).padding(8))
                    .tag(0)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray850)
                    .overlay(SprintMapView(field: field, points: quarter.points).padding(8))
                    .tag(1)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray850)
                    .overlay(
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(.gray500)
                    )
                    .tag(0)
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
            statBadge(.goal, count: detail.goalCount)
            statBadge(.assist, count: detail.assistCount)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statBadge(_ type: MatchEventType, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(type.name)
                .font(.label3M)
            ZStack {
                type.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
                Text(String(count))
                    .font(.display2SB)
                    .padding(.bottom, 40)
            }
        }
    }

    private func sectionView(_ section: AnalysisSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.head2SB)
            
            VStack(spacing: 0) {
                ForEach(section.rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.body4R)
                            .foregroundStyle(.gray400)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(row.value)
                                .font(.body1M)
                                .foregroundStyle(.gray50)
                            Text(row.unit)
                                .font(.body3R)
                                .foregroundStyle(.gray400)
                        }
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
            .scrollDismissesKeyboard(.interactively)

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
        // 입력창 바깥(댓글 목록, 헤더 등)을 탭하면 키보드가 내려간다.
        .dismissKeyboardOnTap()
    }
}

#Preview {
    NavigationStack {
        AnalysisDetailView(entry: .previewSample)
    }
}
