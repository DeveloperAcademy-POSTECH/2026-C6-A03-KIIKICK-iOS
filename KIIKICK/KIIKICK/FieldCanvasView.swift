//
//  FieldCanvasView.swift
//  KIIKICK
//
//  105:68 비율의 검은 배경 + 흰 테두리 운동장 캔버스. 히트맵/스프린트맵 등
//  운동장 위에 뭔가를 그리는 뷰들이 공통으로 이 틀을 재사용한다.
//

import SwiftUI

struct FieldCanvasView: View {
    let draw: (GraphicsContext, CGSize) -> Void

    var body: some View {
        Canvas { context, size in
            // 1. 배경
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

            // 2~3. 내용 (히트맵, 스프린트 화살표 등)
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
