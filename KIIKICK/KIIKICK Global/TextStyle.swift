//
//  TextStyle.swift
//  KIIKICK Global
//
//  Figma node 1:239 "Typography : variables"에서 실측한 값 그대로.
//  rules/DESIGN.md의 Typography 표와 반드시 같이 맞춰서 수정할 것.
//

import SwiftUI

/// SwiftUI가 이미 `Font.TextStyle`을 쓰고 있어서 이름이 겹치지 않게 Kiikick 접두사를 붙였다.
enum KiikickTextStyle {
    case head1B, head2SB, head3B
    case title1SB, title2SB, title3M, title4SB
    case label1M, label2SB, label3M, label4SB
    case body1M, body2R, body3R, body4R
    case caption1M, caption2SB
    case display0SB, display1SB, display2SB, display3SB

    var fontName: String {
        switch self {
        case .head1B, .head3B:
            return "Pretendard-Bold"
        case .head2SB, .title1SB, .title2SB, .title4SB, .label2SB, .label4SB, .caption2SB:
            return "Pretendard-SemiBold"
        case .title3M, .label1M, .label3M, .body1M, .caption1M:
            return "Pretendard-Medium"
        case .body2R, .body3R, .body4R:
            return "Pretendard-Regular"
        case .display0SB, .display1SB, .display2SB, .display3SB:
            return "Kanit-SemiBold"
        }
    }

    var size: CGFloat {
        switch self {
        case .head1B: 28
        case .head2SB: 24
        case .head3B: 20
        case .title1SB: 20
        case .title2SB: 18
        case .title3M: 18
        case .title4SB: 16
        case .label1M: 16
        case .label2SB: 14
        case .label3M: 14
        case .label4SB: 12
        case .body1M: 18
        case .body2R: 18
        case .body3R: 16
        case .body4R: 14
        case .caption1M: 12
        case .caption2SB: 10
        case .display0SB: 64
        case .display1SB: 36
        case .display2SB: 32
        case .display3SB: 24
        }
    }

    /// 폰트 크기 대비 줄 높이 비율(%). Figma의 "line-height" 값 그대로.
    var lineHeightPercent: CGFloat {
        switch self {
        case .head1B, .head2SB, .head3B, .title1SB, .title2SB, .title3M, .title4SB:
            125
        case .label1M, .label2SB, .label3M, .label4SB, .body1M, .body2R, .body3R, .body4R, .caption1M, .caption2SB:
            140
        case .display0SB, .display1SB, .display2SB, .display3SB:
            120
        }
    }

    /// 폰트 크기 대비 자간 비율(%). Figma의 "letter-spacing" 값 그대로.
    var letterSpacingPercent: CGFloat {
        switch self {
        case .head1B, .head2SB, .head3B, .title1SB, .title2SB, .title3M, .title4SB,
             .label1M, .label2SB, .label3M, .body1M, .body2R, .body3R, .body4R:
            -1.5
        case .label4SB, .caption1M, .caption2SB, .display0SB, .display1SB, .display2SB, .display3SB:
            0
        }
    }
}

private struct KiikickTextStyleModifier: ViewModifier {
    let style: KiikickTextStyle

    func body(content: Content) -> some View {
        let lineHeight = style.size * style.lineHeightPercent / 100
        let lineSpacing = max(0, lineHeight - style.size)
        let tracking = style.size * style.letterSpacingPercent / 100

        content
            .font(.custom(style.fontName, size: style.size))
            .tracking(tracking)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    /// Figma Typography 스타일을 그대로 적용한다. 폰트/크기/자간은 정확히 맞고,
    /// 줄 높이는 SwiftUI에 직접 대응하는 속성이 없어 `.lineSpacing`(줄 사이 여백)으로 근사한다.
    /// 현재는 고정 크기이며 Dynamic Type에 상대 스케일링되지 않는다 — 각 스타일을 어떤
    /// 시스템 TextStyle에 연동할지 아직 정해지지 않았기 때문에(Figma에 명시 없음) 임의로
    /// 추측하지 않았다. 필요해지면 `Font.custom(_:size:relativeTo:)`로 바꿀 것.
    func textStyle(_ style: KiikickTextStyle) -> some View {
        modifier(KiikickTextStyleModifier(style: style))
    }
}

extension Font {
    /// `.font(.head1B)`처럼 바로 쓸 수 있는 버전. 폰트/크기만 담고 있고,
    /// 줄 높이·자간까지 Figma 값 그대로 맞추려면 `.textStyle(_:)`를 쓸 것.
    static func kiikick(_ style: KiikickTextStyle) -> Font {
        .custom(style.fontName, size: style.size)
    }

    static var head1B: Font { kiikick(.head1B) }
    static var head2SB: Font { kiikick(.head2SB) }
    static var head3B: Font { kiikick(.head3B) }
    static var title1SB: Font { kiikick(.title1SB) }
    static var title2SB: Font { kiikick(.title2SB) }
    static var title3M: Font { kiikick(.title3M) }
    static var title4SB: Font { kiikick(.title4SB) }
    static var label1M: Font { kiikick(.label1M) }
    static var label2SB: Font { kiikick(.label2SB) }
    static var label3M: Font { kiikick(.label3M) }
    static var label4SB: Font { kiikick(.label4SB) }
    static var body1M: Font { kiikick(.body1M) }
    static var body2R: Font { kiikick(.body2R) }
    static var body3R: Font { kiikick(.body3R) }
    static var body4R: Font { kiikick(.body4R) }
    static var caption1M: Font { kiikick(.caption1M) }
    static var caption2SB: Font { kiikick(.caption2SB) }
    static var display0SB: Font { kiikick(.display0SB) }
    static var display1SB: Font { kiikick(.display1SB) }
    static var display2SB: Font { kiikick(.display2SB) }
    static var display3SB: Font { kiikick(.display3SB) }
}
