//
//  BtnSelectionView.swift
//  KIIKICK Watch App Watch App
//
//  Figma node 249:549 "btn_selection"
//

import SwiftUI

struct BtnSelectionView: View {
    var text: String = "KK"
    var style: BtnSelectionStyle = .primary
    let action: () -> Void
    
    enum BtnSelectionStyle {
        case primary, selected

        var background: Color {
            switch self {
            case .primary: return .colorSurfacePrimary
            case .selected: return .colorSurfaceElevated
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .selected: return .textBrand
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title4SB)
                .tracking(-0.24)
                .lineSpacing(4)
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 6)
                .frame(width: 48, height: 32)
                .background(style.background, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Apple Watch Series 9 - 45mm") {
    BtnSelectionView {}
}
