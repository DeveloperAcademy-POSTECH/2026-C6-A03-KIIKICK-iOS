//
//  Color+Semantic.swift
//  KIIKICK Global
//
//  rules/DESIGN.md의 "Colors — Semantic" 표에서 실측한 Figma Variable 바인딩 그대로.
//  각 값은 새 hex를 만들지 않고 Assets.xcassets의 Primitive Color Set을 그대로 가리킨다.
//  Figma 쪽 변수 이름 표기가 제각각(kebab-case/path)이라 Swift 쪽은 lowerCamelCase로 옮겼다.
//

import SwiftUI

extension Color {
    /// Figma `color-text-primary` / `icon/default` → `gray50`
    static var colorTextPrimary: Color { .gray50 }

    /// Figma `color-text-secondary`(node 733:9112 "overall" 프레임에서 실측) → `gray400`
    static var colorTextSecondary: Color { .gray400 }

    /// Figma `color-surface-primary` → `gray850`
    static var colorSurfacePrimary: Color { .gray850 }
    
    /// Figma `color-background-secondary` → `gray900`
    static var colorBackgroundSecondary: Color { .gray900 }
    
    /// Figma `surface/darken` (어두운 민트 계열 표면) → `mint950`
    static var surfaceDarken: Color { .mint950 }
    
    /// Figma `text/brand` (= `mint-500`) → `mint500`
    static var textBrand: Color { .mint500 }
    
    /// Figma `action/destructive` → `red500`
    static var actionDestructive: Color { .red500 }
    
    /// Figma `brand/gray` (중립 브랜드 변형) → `gray500`
    static var brandGray: Color { .gray500 }

    /// Figma `background/primary` → `gray950`
    static var colorBackgroundPrimary: Color { .gray950 }

    /// Figma `brand/primary` (node 313:2 35개 토큰 표 기준. `text/brand`와 값은 같지만(mint500)
    /// 별도 row로 존재 — 텍스트가 아닌 보더/강조 용도로 쓸 때는 이쪽을 쓴다.
    /// "border/brand"라는 이름의 row는 그 표에 없어서 만들지 않았다.
    static var brandPrimary: Color { .mint500 }
}

// Asset Catalog 자동생성 심볼(`GeneratedAssetSymbols.swift`)과 동일하게, `.fill(.colorSurfacePrimary)`처럼
// leading-dot으로 쓰려면 `ShapeStyle` 쪽에도 별도로 선언해야 한다 — `Color` extension만으로는 안 된다.
extension ShapeStyle where Self == Color {
    static var colorTextPrimary: Color { .colorTextPrimary }
    static var colorTextSecondary: Color { .colorTextSecondary }
    static var colorSurfacePrimary: Color { .colorSurfacePrimary }
    static var colorBackgroundSecondary: Color { .colorBackgroundSecondary }
    static var surfaceDarken: Color { .surfaceDarken }
    static var textBrand: Color { .textBrand }
    static var actionDestructive: Color { .actionDestructive }
    static var brandGray: Color { .brandGray }
    static var colorBackgroundPrimary: Color { .colorBackgroundPrimary }
    static var brandPrimary: Color { .brandPrimary }
}
