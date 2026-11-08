//
//  UserProfileView.swift
//  KIIKICK
//
//  Figma node 575:5845(친구 상태, 경기 기록 추가) / 309:1413(친구 아닌 상태) / 309:1429(친구 요청 보낸 상태)
//  "friend_profile" (iOS 화면), 309:1476 "Alert"(친구 삭제 확인) — 네이티브 iOS Alert(HIG) 컴포넌트
//
//  DESIGN-GAP: 스크롤하면 상단 타이틀이 "프로필"에서 닉네임으로 바뀌는 variant(575:5868)가
//  있지만, 이 앱에 그런 스크롤 연동 타이틀 패턴이 아직 없어 "프로필" 고정으로 구현했다.
//  "함께 뛴 경기" 기록을 보여줄 실제 데이터 연동이 없어서(이슈 #26도 뷰 구현만 범위) 지금은
//  빈 목록이다.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var status: FriendshipStatus
    @State private var isPresentingRemoveConfirm = false
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var month = Calendar.current.component(.month, from: Date())
    let nickname: String
    var onAddFriend: () -> Void = {}
    var onRemoveFriend: () -> Void = {}

    init(user: UserProfile, onAddFriend: @escaping () -> Void = {}, onRemoveFriend: @escaping () -> Void = {}) {
        self.nickname = user.nickname
        self._status = State(initialValue: user.status)
        self.onAddFriend = onAddFriend
        self.onRemoveFriend = onRemoveFriend
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 24) {
                    Image("img_profile_default")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    Text(nickname)
                        .font(.head2SB)
                        .foregroundStyle(.gray50)
                }
                .padding(.top, 24)

                switch status {
                case .friend:
                    VStack(alignment: .leading, spacing: 24) {
                        DatePickerView(year: $year, month: $month)

                        VStack(spacing: 24) {
                            ForEach([AnalysisEntry]()) { entry in
                                CardSummaryView(
                                    dateAndQuarter: entry.dateAndQuarter,
                                    fieldName: entry.fieldName,
                                    stats: entry.stats.map { CardSummaryView.Stat(label: $0.label, value: $0.value, unit: $0.unit) }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                case .none:
                    VStack(spacing: 8) {
                        CtaView(text: "친구 추가", type: .primary, size: .large) {
                            status = .requestSent
                            onAddFriend()
                        }
                    }
                    .padding(.top, 48)

                case .requestSent:
                    VStack(spacing: 8) {
                        CtaView(text: "신청 완료", type: .primary, size: .large, isActive: false) {}
                        VStack(spacing: 8) {
                            Text("친구 신청을 보냈어요")
                                .font(.caption1M)
                                .foregroundStyle(.mint500)
                            Text("상대가 수락하면 친구 목록에 표시돼요")
                                .font(.caption1M)
                                .foregroundStyle(.gray400)
                        }
                    }
                    .padding(.top, 48)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if status == .friend {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("친구 삭제", role: .destructive) {
                            isPresentingRemoveConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .alert("\(nickname)님을 친구에서 삭제할까요?", isPresented: $isPresentingRemoveConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                onRemoveFriend()
                dismiss()
            }
        } message: {
            Text("친구 목록에서 사라지며, 다시 친구가 되려면 친구 신청이 필요해요")
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "갱아", status: .friend))
    }
}

#Preview("친구 아님") {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "조승연", status: .none))
    }
}

#Preview("요청 보냄") {
    NavigationStack {
        UserProfileView(user: UserProfile(nickname: "조승연", status: .requestSent))
    }
}
