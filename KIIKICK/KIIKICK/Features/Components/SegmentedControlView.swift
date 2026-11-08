//
//  SegmentedControlView.swift
//  KIIKICK
//
//  Figma node 357:1349 "Segmented control" (Type=analysis/comment, Assets&Components 페이지)
//

import SwiftUI

struct SegmentedControlView<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(.label2SB)
                        .foregroundStyle(.gray50)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .frame(maxHeight: .infinity)
                        .background(
                            selection == option.value ? Color.gray850 : Color.clear,
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(height: 36)
        .background(Color.gray1000, in: RoundedRectangle(cornerRadius: 100))
    }
}

#Preview {
    @Previewable @State var selection = "analysis"
    return SegmentedControlView(
        options: [(value: "analysis", label: "분석"), (value: "comment", label: "댓글")],
        selection: $selection
    )
    .padding()
    .background(Color.gray950)
}
