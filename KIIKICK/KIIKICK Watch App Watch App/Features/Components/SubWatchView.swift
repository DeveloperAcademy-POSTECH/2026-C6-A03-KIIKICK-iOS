//
//  SubWatchView.swift
//  KIIKICK Watch App Watch App
//
//  Figma node 246:56 "sub-watch"
//

import SwiftUI

struct SubWatchView: View {
    
    var icon: Image = Image("ic_pause")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(.gray50)
                .padding(.horizontal, 6)
                .padding(.vertical, 12)
                .frame(width: 147)
                .background(.gray850, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Apple Watch Series 9 - 45mm") {
    SubWatchView {}
}
