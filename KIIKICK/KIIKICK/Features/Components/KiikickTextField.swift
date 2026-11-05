//
//  KiikickTextField.swift
//  KIIKICK
//
//  Figma node 256:918 "textfield" (Assets&Components 페이지)
//

import SwiftUI

enum KiikickTextFieldState {
    case `default`, writing, completed, error
}

struct KiikickTextField: View {
    @Binding var text: String
    var placeholder: String = "placeholder"
    var state: KiikickTextFieldState = .default
    var errorMessage: String = ""
    var maxCount: Int? = nil
    var isSecure: Bool = false

    private var borderColor: Color {
        switch state {
        case .error: return .red500
        case .completed: return .mint500
        case .default, .writing: return .gray700
        }
    }

    private var textColor: Color {
        state == .default ? .gray400 : .gray50
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                    .font(state == .default ? .body2R : .body1M)
                    .foregroundStyle(textColor)
                
                if state == .completed {
                    Image("ic_success")
                        .resizable()
                        .frame(width: 24, height: 24)
                } else if state == .error {
                    Image("ic_delete")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(Color.gray800, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            
            if state == .error {
                HStack {
                    Text(errorMessage)
                        .font(.caption1M)
                        .foregroundStyle(.red500)
                    if let maxCount {
                        Spacer()
                        Text(verbatim: "\(text.count)/\(maxCount)")
                            .font(.caption1M)
                            .foregroundStyle(.red500)
                    }
                }
                .padding(.horizontal, 4)
            } else if let maxCount {
                Text(verbatim: "\(text.count)/\(maxCount)")
                    .font(.caption1M)
                    .foregroundStyle(state == .completed ? .mint500 : .gray400)
                    .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        KiikickTextField(text: .constant(""), maxCount: 8)
        KiikickTextField(text: .constant("작성중.."), state: .writing, maxCount: 8)
        KiikickTextField(text: .constant("작성완료"), state: .completed, maxCount: 8)
        KiikickTextField(text: .constant("작성중 ..."), state: .error, errorMessage: "에러메세지", maxCount: 8)
    }
    .padding()
    .background(Color.gray950)
}
