//
//  ListFriendView.swift
//  KIIKICK
//
//  Figma node 309:1288 "list_friend" (Assets&Components 페이지)
//

import SwiftUI

struct ListFriendView: View {
    let name: String
    var profileImage: Image? = nil
    var isWaiting: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 12) {
                (profileImage ?? Image(systemName: "person.crop.circle.fill"))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                Text(name)
                    .font(.body1M)
                    .foregroundStyle(.gray50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isWaiting {
                Text("대기중")
                    .font(.label4SB)
                    .foregroundStyle(.gray50)
                    .padding(8)
                    .background(Color.gray850, in: Capsule())
            }

            Image("ic_arrow")
                .resizable()
                .frame(width: 24, height: 24)
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        ListFriendView(name: "닉네임", isWaiting: true)
        ListFriendView(name: "닉네임")
    }
    .padding()
    .background(Color.gray950)
}
