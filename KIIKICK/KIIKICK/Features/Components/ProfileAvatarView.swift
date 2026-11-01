//
//  ProfileAvatarView.swift
//  KIIKICK
//
//  Figma node 309:1406 "Avatar / default profile" (friend_profile 화면, Assets&Components 페이지)
//

import SwiftUI

struct ProfileAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray850)
                .frame(width: 104, height: 104)
            Image("ic_person")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.gray400)
                .frame(width: 47.84, height: 47.84)
        }
    }
}

#Preview {
    ProfileAvatarView()
        .padding()
        .background(Color.gray950)
}
