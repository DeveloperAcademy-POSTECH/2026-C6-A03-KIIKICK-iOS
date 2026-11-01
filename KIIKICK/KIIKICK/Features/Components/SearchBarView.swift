//
//  SearchBarView.swift
//  KIIKICK
//
//  Figma node 256:913 "searchbar" (Assets&Components 페이지)
//

import SwiftUI

enum SearchBarState {
    case `default`, writing, completed
}

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "placeholder"
    var state: SearchBarState = .default
    var onClear: () -> Void = {}

    private var borderColor: Color {
        state == .completed ? .mint700 : .gray700
    }

    var body: some View {
        HStack(spacing: 4) {
            if state == .default {
                TextField(placeholder, text: $text)
                    .font(.body2R)
                    .foregroundStyle(.gray400)
                Image("ic_search")
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                TextField(placeholder, text: $text)
                    .font(.body1M)
                    .foregroundStyle(.gray50)
                if state == .writing {
                    Button(action: onClear) {
                        Image("ic_delete")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(height: 52)
        .background(Color.gray800, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        SearchBarView(text: .constant(""))
        SearchBarView(text: .constant("작성중.."), state: .writing)
        SearchBarView(text: .constant("작성완료"), state: .completed)
    }
    .padding()
    .background(Color.gray950)
}
