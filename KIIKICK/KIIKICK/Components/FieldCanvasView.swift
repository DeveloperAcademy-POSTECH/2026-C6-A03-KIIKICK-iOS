//
//  FieldCanvasView.swift
//  KIIKICK
//
//  105:68 비율의 검은 배경 + 흰 테두리 운동장 캔버스 -> 히트맵/스프린트맵 등
//

import SwiftUI

struct FieldCanvasView: View {
    let draw: (GraphicsContext, CGSize) -> Void
    
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            
            // 2~3. 내용 (히트맵, 스프린트, 화살표 등)
            draw(context, size)
            
            // 4. 필드 테두리
            context.stroke(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white),
                lineWidth: 2
            )
        }
        .aspectRatio(105.0 / 68.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
