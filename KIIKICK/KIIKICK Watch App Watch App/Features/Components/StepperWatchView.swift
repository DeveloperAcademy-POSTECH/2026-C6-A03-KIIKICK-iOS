//
//  StepperView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct StepperWatchView: View {
    
    @State var count: Int = 0

    var body: some View {
        HStack(spacing: 25) {
            Button {
                count -= 1
            } label: {
                ZStack {
                    Capsule()
                        .fill(.gray400)
                    Image(systemName: "minus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.gray50)
                }
                .frame(width: 48, height: 60)
            }
            .buttonStyle(.plain)
            .disabled(count <= 0)
            
            Text(String(count))
                .textStyle(.head1B)
                .foregroundStyle(.white)
                .frame(minWidth: 20)
            
            Button {
                count += 1
            } label: {
                ZStack {
                    Capsule()
                        .fill(.mint500)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.gray50)
                }
                .frame(width: 48, height: 60)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Apple Watch Series 9 - 45mm") {
    StepperWatchView()
}
