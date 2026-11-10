//
//  CommentComposerView.swift
//  KIIKICK
//
//  Figma node 355:1324 "TextfieldComment" (이슈 #17).
//

import SwiftUI

struct CommentComposerView: View {
    @Binding var text: String
    var isActive = true
    var isSubmitting = false
    var onSend: () -> Void

    private var isSendDisabled: Bool {
        !isActive || isSubmitting || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("댓글을 입력하세요", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .disabled(isSubmitting)
                .font(.body4R)
                .foregroundStyle(.gray50)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray900, in: RoundedRectangle(cornerRadius: 20))

            Button(action: onSend) {
                Text("전송")
                    .font(.label2SB)
                    .foregroundStyle(isSendDisabled ? .gray500 : .mint500)
            }
            .buttonStyle(.plain)
            .disabled(isSendDisabled)
        }
        .padding(16)
        .background(Color.gray950)
    }
}

#Preview {
    CommentComposerView(text: .constant(""), onSend: {})
        .background(Color.gray850)
}
