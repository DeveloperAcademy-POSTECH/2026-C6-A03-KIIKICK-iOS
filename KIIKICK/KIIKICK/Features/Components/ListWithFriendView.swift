//
//  ListWithFriendView.swift
//  KIIKICK
//
//  Figma node 371:3739 "list_withfriend" (이슈 #17). 기존 list_friend(ListFriendView)와
//  데이터 모양이 달라서(대기중 칩 대신 삭제 칩) 별도 컴포넌트로 분리했다.
//

import SwiftUI

struct ListWithFriendView: View {
    let name: String
    var profileImage: Image? = nil
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                (profileImage ?? Image("img_profile_default"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                Text(name)
                    .font(.body1M)
                    .foregroundStyle(.gray50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Text("삭제")
                    .font(.label4SB)
                    .foregroundStyle(.red500)
                    .padding(8)
                    .background(Color.gray850, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        ListWithFriendView(name: "갱아", onDelete: {})
        ListWithFriendView(name: "루디", onDelete: {})
    }
    .padding()
    .background(Color.gray950)
}
