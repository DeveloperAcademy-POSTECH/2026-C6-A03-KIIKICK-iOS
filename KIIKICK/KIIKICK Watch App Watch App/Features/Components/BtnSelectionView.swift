//
//  BtnSelectionView.swift
//  KIIKICK Watch App Watch App
//
//  Figma node 249:549 "btn_selection"
//

import SwiftUI

struct BtnSelectionView: View {
    var text: String = "KK"
    let action: () -> Void
    var style: BtnSelectionStyle = .primary
    
    // DESIGN-GAP: Figma btn_selection(249:549)에는 variant가 없고 기본(gray850/white) 상태만
    // 정의돼 있다. selected는 Figma에 없는 상태라, 다른 컴포넌트의 "선택됨 = mint500" 관례
    // (CtaWatchView primary, Stepper increment)를 따라 임의로 추가했다.
    enum BtnSelectionStyle {
        case primary, selected

        var background: Color {
            switch self {
            case .primary: return .gray850
            case .selected: return .mint950
            }
        }

        var foreground: Color {
            switch self {
            case .primary: return .white
            case .selected: return .black
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                // DESIGN-GAP: Figma는 이 텍스트를 title4_sb로 라벨링했지만 실제 해석된
                // 크기는 --font-size-md(16px)로 DESIGN.md의 title4_sb(14px)와 다르다.
                // 기존 토큰에 안 맞아 임의로 추가하지 않고 이 컴포넌트 안에서만 직접 구현.
                .font(.custom("Pretendard-SemiBold", size: 16))
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
