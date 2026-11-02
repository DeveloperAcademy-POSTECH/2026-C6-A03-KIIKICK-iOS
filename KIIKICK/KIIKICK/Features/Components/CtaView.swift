//
//  CtaView.swift
//  KIIKICK
//
//  Figma node 241:638 "cta" (Assets&Components 페이지)
//

import SwiftUI

enum CtaType {
    case primary, secondary, sub, destructive
}

enum CtaSize {
    case large, small
}

/// `size: .large`는 Figma 기준대로 항상 주어진 가로 공간을 꽉 채운다. `size: .small`은
/// 기본적으로 텍스트 길이만큼만 차지(hug)하고, 여러 개를 나란히 동일 너비로 채우고 싶으면
/// (예: 수락/거절 버튼) `fillWidth: true`를 명시적으로 넘길 것.
struct CtaView: View {
    let text: String
    var type: CtaType = .primary
    var size: CtaSize = .large
    var icon: Image? = nil
    var isActive: Bool = true
    var fillWidth: Bool? = nil
    let action: () -> Void

    private var shouldFillWidth: Bool {
        fillWidth ?? (size == .large)
    }

    private var background: Color {
        guard isActive else { return .gray500 }
        switch type {
        case .primary: return .mint500
        case .secondary, .sub, .destructive: return .gray850
        }
    }

    private var foreground: Color {
        guard isActive else { return .gray900 }
        switch type {
        case .primary: return .gray900
        case .secondary: return .mint500
        case .sub: return .gray50
        case .destructive: return .red500
        }
    }

    private var font: Font {
        size == .large ? .title2SB : .label1M
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size == .large ? 24 : 12, height: size == .large ? 24 : 12)
                }
                Text(text)
                    .font(font)
            }
            .foregroundStyle(foreground)
            .padding(.vertical, size == .large ? 16 : 12)
            .padding(.horizontal, size == .large ? 0 : 16)
            .frame(maxWidth: shouldFillWidth ? .infinity : nil)
            .frame(height: size == .large ? 55 : 46)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}
