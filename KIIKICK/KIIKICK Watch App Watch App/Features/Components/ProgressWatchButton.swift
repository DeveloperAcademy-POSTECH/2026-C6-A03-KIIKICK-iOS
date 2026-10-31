//
//  ProgressWatchView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct ProgressWatchButton: View {
    enum Progress {
        case play, pause
        
        var icon: Image {
            switch self {
            case .play:
                return Image("ic_pause")
            case .pause:
                return Image("ic_play")
            }
        }
        
        mutating func toggle() {
            switch self {
            case .play:
                self = .pause
            case .pause:
                self = .play
            }
        }
    }
    
    @State var progress: Progress = .play
    
    var body: some View {
        Button(action: action) {
            progress.icon
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(Color("Gray50"))
                .padding(.horizontal, 6)
                .padding(.vertical, 12)
                .frame(width: 147)
                .background(Color("Gray850"), in: Capsule())
        }
        .buttonStyle(.plain)
    }
    
    func action() {
        progress.toggle()
    }
}

#Preview {
    ProgressWatchButton()
}
