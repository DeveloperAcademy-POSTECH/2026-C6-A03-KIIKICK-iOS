//
//  CtaWatchView.swift
//  KIIKICK Watch App Watch App
//
//  Figma node 241:4091 "cta-watch"
//

import SwiftUI

enum CtaWatchType {
    case primary
    case destructive
}

struct CtaWatchView: View {
    let text: String
    var type: CtaWatchType = .primary
    let action: () -> Void
    
    private var background: Color {
        switch type {
        case .primary: return .mint500
        case .destructive: return .gray900
        }
    }

    private var foreground: Color {
        switch type {
        case .primary: return .black
        case .destructive: return .red500
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .textStyle(.title1SB)
                .foregroundStyle(foreground)
                .padding(.horizontal, 6)
                .padding(.vertical, 12)
                .frame(minWidth: 147)
                .frame(height: 49)
                .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
