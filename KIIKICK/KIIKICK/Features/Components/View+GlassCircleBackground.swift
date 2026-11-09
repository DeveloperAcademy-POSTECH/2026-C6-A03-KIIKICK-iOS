//
//  View+GlassCircleBackground.swift
//  KIIKICK
//
//  HomeView 헤더의 원형 아이콘 버튼("+"/알림)에 쓰는 유리질감(Glassmorphism) 배경.
//  앱이 시스템 설정과 무관하게 항상 다크 톤이라, Material이 라이트 모드 기기에서
//  밝게 뒤집히지 않도록 `.environment(\.colorScheme, .dark)`로 다크 변형을 고정한다.
//
//  DESIGN-GAP: 정확한 블러 반경·보더 투명도·그림자 값은 Figma에서 별도 확인하지
//  않았다 — 일반적인 글래스모피즘 조합(ultraThinMaterial + 대각선 라이트 보더 +
//  옅은 그림자)으로 근사했다.
//

import SwiftUI

extension View {
    func glassCircleBackground() -> some View {
        self
            .background {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}
