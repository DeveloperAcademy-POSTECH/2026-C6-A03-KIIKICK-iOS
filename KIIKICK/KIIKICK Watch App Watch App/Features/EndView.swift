//
//  EndView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct EndView: View {
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130)
            Text("iPhone에서\n 경기를 준비해주세요")
        }
        .task {
            do {
                try await Task.sleep(for: .seconds(2))
                action()
            } catch {
                // 뷰 해제되었을 때
            }
        }
    }
}
