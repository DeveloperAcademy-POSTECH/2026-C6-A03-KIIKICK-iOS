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
        // state에 따라 서로 다른 TextField를 if/else로 그리면 상태가 바뀔 때마다(예: 빈 값 →
        // 입력 시작) SwiftUI가 TextField를 새 view identity로 다시 만들어 포커스/키보드를 잃는다.
        // 하나의 TextField를 유지하고 폰트·색만 조건부로 바꿔서 identity를 안정적으로 유지한다.
        HStack(spacing: 4) {
            TextField(placeholder, text: $text)
                .font(state == .default ? .body2R : .body1M)
                .foregroundStyle(state == .default ? .gray400 : .gray50)

            if state == .writing {
                Button(action: onClear) {
                    Image("ic_delete")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            } else if state == .default {
                Image("ic_search")
                    .resizable()
                    .frame(width: 24, height: 24)
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
