import SwiftUI

/// img_field 위의 실제 운동장 영역에 히트맵·스프린트 맵을 겹쳐 그린다.
struct FieldCanvasView: View {
    let draw: (GraphicsContext, CGSize) -> Void

    var body: some View {
        Canvas { context, size in
            context.draw(Image("img_field"), in: CGRect(origin: .zero, size: size))
            let fieldRect = FieldArtworkLayout.fieldRect(in: size)
            var overlay = context
            overlay.clip(to: Path(fieldRect))
            overlay.translateBy(x: fieldRect.minX, y: fieldRect.minY)
            draw(overlay, fieldRect.size)
        }
        .aspectRatio(FieldArtworkLayout.artworkSize.width / FieldArtworkLayout.artworkSize.height, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}
