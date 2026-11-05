//
//  NotificationWithFriendView.swift
//  KIIKICK
//
//  Figma node 516:5273 "notification_withfriend" (Assets&Components 페이지, 이슈 #25에서 추가됨)
//

import SwiftUI

struct NotificationWithFriendView: View {
    let nickname: String
    let matchDate: Date
    var profileImage: Image? = nil

    private var matchDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 경기"
        return formatter.string(from: matchDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            (profileImage ?? Image("img_profile_default"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(nickname)님이 회원님을 함께 뛴 친구로 추가했어요")
                    .font(.label3M)
                    .foregroundStyle(.gray50)
                Text(matchDateText)
                    .font(.caption1M)
                    .foregroundStyle(.gray400)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image("ic_arrow")
                .resizable()
                .frame(width: 24, height: 24)
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NotificationWithFriendView(nickname: "닉네임", matchDate: Date())
        .padding()
        .background(Color.gray950)
}
