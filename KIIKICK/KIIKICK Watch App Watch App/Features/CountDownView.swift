//
//  CountDownView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct CountDownView: View {
    
    var action: () -> Void
    
    @State var time: Int = 3
    
    var body: some View {
        Text("\(time)")
            .font(.custom("Pretendard-SemiBold", size: 68))
            .task {
                do {
                    while time > 1 {
                        try await Task.sleep(for: .seconds(1))
                        time -= 1
                    }
                    try await Task.sleep(for: .seconds(1))
                    action()
                } catch {
                    // 뷰가 사라져서 취소된 경우
                }
            }
            .onTapGesture {
                action()
            }
    }
}
