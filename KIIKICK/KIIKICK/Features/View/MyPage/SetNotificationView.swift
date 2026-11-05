//
//  SetNotificationView.swift
//  KIIKICK
//
//  Figma node 392:4495 "setNotificaiton" (iOS 화면)
//
//  DESIGN-GAP: 알림 수신 여부를 서버/푸시 토큰에 반영하는 API가 아직 없어, 토글은 로컬
//  상태로만 동작한다 (껐다 켜도 다음 실행 시 기본값으로 돌아간다).
//

import SwiftUI

struct SetNotificationView: View {
    @State private var isFriendRequestOn = true
    @State private var isCommentOn = true
    @State private var isAnalysisCompleteOn = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("받고 싶은 알림을 선택해주세요")
                    .font(.body4R)
                    .foregroundStyle(.gray400)

                notificationSection(title: "활동 알림") {
                    notificationRow(title: "친구 신청", description: "새로운 친구 신청과 수락 소식", isOn: $isFriendRequestOn)
                    notificationRow(title: "댓글", description: "내 기록에 달린 댓글과 답글", isOn: $isCommentOn)
                }

                notificationSection(title: "기록 알림") {
                    notificationRow(title: "분석 완료", description: "경기 분석이 완료되면 알려드려요.", isOn: $isAnalysisCompleteOn)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("알림이 오지 않나요?")
                    Text("기기의 설정에서 알림 권한을 확인해주세요.")
                }
                .font(.body4R)
                .foregroundStyle(.gray400)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("알림 설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder
    private func notificationSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3M)
                .foregroundStyle(.gray400)
            VStack(spacing: 8) {
                content()
            }
            .padding(16)
            .background(Color.gray850, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func notificationRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title4SB)
                    .foregroundStyle(.gray50)
                Text(description)
                    .font(.body4R)
                    .foregroundStyle(.gray400)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.mint500)
        }
        .frame(height: 64)
    }
}

#Preview {
    NavigationStack {
        SetNotificationView()
    }
}
