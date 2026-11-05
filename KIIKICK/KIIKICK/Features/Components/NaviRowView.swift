//
//  NaviRowView.swift
//  KIIKICK
//
//  Figma `navi_row` 컴포넌트(아이콘 + 텍스트 + 화살표, 탭 가능한 행).
//  정확한 인스턴스 사이즈는 이번 세션에 재검증하지 못해 카탈로그 일반값(354×64)을 기준으로
//  patting/spacing을 잡았다 — DESIGN-GAP.
//

import SwiftUI

/// 탭 동작은 넣지 않은 순수 표시용 행이다 — 호출부가 `NavigationLink(value:)`나 `Button`으로
/// 감싸는 방식이 다를 수 있어서(예: 화면 이동 vs. 다른 액션) 여기서 탭 제스처를 고정하지 않았다.
struct NaviRowView: View {
    var icon: Image? = nil
    let text: String
    var textStyle: KiikickTextStyle = .body4R
    var textColor: Color = .colorTextPrimary
    /// 기본은 화면 이동을 뜻하는 화살표(`ic_arrow`). 외부 링크로 나가는 행은 `ic_link`로 바꿔 쓴다.
    var trailingIconName: String = "ic_arrow"

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                icon
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            Text(text)
                .textStyle(textStyle)
                .foregroundStyle(textColor)
            Spacer()
            Image(trailingIconName)
                .resizable()
                .frame(width: 24, height: 24)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NaviRowView(icon: Image(systemName: "sparkles"), text: "새로운 분석지가 도착했어요! 확인해보세요")
        .padding()
        .background(Color.gray950)
}
