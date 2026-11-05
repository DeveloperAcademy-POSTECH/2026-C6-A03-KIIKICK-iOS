//
//  View+DismissKeyboardOnTap.swift
//  KIIKICK
//
//  KiikickTextField / SearchBarView 등을 쓰는 화면에서, 키보드가 떠 있을 때
//  입력 필드 바깥을 탭하면 키보드가 내려가게 하는 공용 modifier.
//

import SwiftUI

extension View {
    /// 이 뷰 영역 어디를 탭해도 포커스 중인 텍스트 입력의 키보드를 내린다.
    /// `simultaneousGesture`라서 버튼 등 다른 탭 제스처를 막지 않는다.
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
