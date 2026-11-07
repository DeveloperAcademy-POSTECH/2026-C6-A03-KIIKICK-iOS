//
//  ComponentsPreview.swift
//  KIIKICK
//
//  Figma node 1:440 "Assets&Components"에서 구현한 iOS 컴포넌트를 한 화면에 모아 보는 뷰.
//  실기기/시뮬레이터에서 디자인 QA용으로 쓴다.
//

import SwiftUI

struct ComponentsPreview: View {
    @State private var textFieldValue = ""
    @State private var searchValue = ""
    @State private var metric: PerformanceMetric = .speed
    @State private var year = 2026
    @State private var month = 10

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section("CTA") {
                    VStack(alignment: .leading, spacing: 12) {
                        CtaView(text: "버튼", type: .primary, action: {})
                        CtaView(text: "버튼", type: .secondary, action: {})
                        CtaView(text: "버튼", type: .sub, action: {})
                        CtaView(text: "버튼", type: .destructive, action: {})
                        CtaView(text: "버튼", type: .primary, isActive: false, action: {})
                        HStack(spacing: 8) {
                            VStack {
                                CtaView(text: "버튼", type: .primary, size: .small, icon: Image(systemName: "plus"), action: {})
                                CtaView(text: "버튼", type: .secondary, size: .small, icon: Image(systemName: "plus"), action: {})
                            }
                            VStack {
                                CtaView(text: "버튼", type: .sub, size: .small, icon: Image(systemName: "plus"), action: {})
                                CtaView(text: "버튼", type: .destructive, size: .small, icon: Image(systemName: "plus"), action: {})
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                section("TextField") {
                    VStack(spacing: 12) {
                        KiikickTextField(text: $textFieldValue, maxCount: 8)
                        KiikickTextField(text: .constant("작성중.."), state: .writing, maxCount: 8)
                        KiikickTextField(text: .constant("작성완료"), state: .completed, maxCount: 8)
                        KiikickTextField(text: .constant("작성중 ..."), state: .error, errorMessage: "에러메세지", maxCount: 8)
                    }
                }

                section("SearchBar") {
                    VStack(spacing: 12) {
                        SearchBarView(text: $searchValue)
                        SearchBarView(text: .constant("작성중.."), state: .writing)
                        SearchBarView(text: .constant("작성완료"), state: .completed)
                    }
                }

                section("NotificationFriend") {
                    VStack(spacing: 12) {
                        NotificationFriendView(nickname: "닉네임", status: .pending)
                        NotificationFriendView(nickname: "닉네임", status: .accepted)
                        NotificationFriendView(nickname: "닉네임", status: .rejected)
                    }
                }

                section("ListFriend") {
                    VStack(spacing: 12) {
                        ListFriendView(name: "닉네임", isWaiting: true)
                        ListFriendView(name: "닉네임")
                    }
                }

                section("NotificationComment") {
                    NotificationCommentView(nickname: "닉네임", commentPreview: "댓글 내용내용내용")
                }

                section("DatePicker") {
                    DatePickerView(
                        year: $year, month: $month,
                        availableYearMonths: [YearMonth(year: 2025, month: 9), YearMonth(year: 2026, month: 10)]
                    )
                }

                section("CardSummary") {
                    CardSummaryView(
                        dateAndQuarter: "00월 00일 • 총 0Q",
                        fieldName: "경기장 이름",
                        stats: [
                            .init(label: "최고속도", value: "22.6", unit: "km/h"),
                            .init(label: "이동거리", value: "2.48", unit: "km"),
                            .init(label: "소모 칼로리", value: "245", unit: "kcal"),
                        ]
                    )
                }

                section("PerformanceTrends") {
                    PerformanceTrendsView(
                        selectedMetric: $metric,
                        points: (0..<8).map { PerformanceTrendPoint(quarterIndex: $0, value: Double.random(in: 15...25)) },
                        unit: "km/h",
                        dateLabel: "10월 28일 · Q4",
                        yAxisValues: [0, 10, 20, 30],
                        visibleRangeStart: 0.666,
                        visibleRangeWidth: 0.333
                    )
                }
            }
            .padding()
        }
        .background(Color.gray950)
        .dismissKeyboardOnTap()
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title1SB)
                .foregroundStyle(.gray50)
            content()
        }
    }
}

#Preview {
    ComponentsPreview()
}
