//
//  View+GradientForeground.swift
//  KIIKICK
//
//  "분석 디테일" 화면의 그라디언트 텍스트(CTA/"Key Stats"/섹션 헤더 3개)용 공용 헬퍼.
//  DESIGN-GAP: 정확한 gradient stop·각도를 Figma Variable로 재확인하지 못해
//  mint500→mint300(좌→우)으로 근사했다.
//

import SwiftUI

extension View {
    func gradientForeground(_ colors: [Color] = [.mint500, .mint300]) -> some View {
        self
            .overlay(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
            )
            .mask(self)
    }
}
