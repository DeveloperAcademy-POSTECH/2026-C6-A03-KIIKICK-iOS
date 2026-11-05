//
//  ListEventView.swift
//  KIIKICK
//
//  Figma node 511:4866 "list_event" (Type=assist/goal, Assets&Components 페이지)
//

import SwiftUI

enum MatchEventType {
    case goal, assist
}

struct ListEventView: View {
    let type: MatchEventType
    let number: Int
    let time: String

    var body: some View {
        HStack(spacing: 4) {
            Image(type == .goal ? "ic_goal" : "ic_assist")
                .renderingMode(.original)
                .resizable()
                .frame(width: 28, height: 28)
            Text(type == .goal ? "Goal \(number)" : "Assist \(number)")
                .font(.label2SB)
                .foregroundStyle(.gray50)
            Spacer()
            Text(time)
                .font(.label2SB)
                .foregroundStyle(.gray50)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 0) {
        ListEventView(type: .goal, number: 1, time: "00:00")
        ListEventView(type: .assist, number: 1, time: "00:00")
    }
    .padding()
    .background(Color.gray950)
}
