//
//  StepperView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct StepperWatchView: View {

    @Binding var count: Int
    var onIncrement: () -> Void = {}
    var onDecrement: () -> Void = {}

    var body: some View {
        HStack(spacing: 25) {
            Button {
                count -= 1
                onDecrement()
            } label: {
                ZStack {
                    Capsule()
                        .fill(.brandGray)
                    Image(systemName: "minus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.colorTextPrimary)
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
                onIncrement()
            } label: {
                ZStack {
                    Capsule()
                        .fill(.mint500)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.colorTextPrimary)
                }
                .frame(width: 48, height: 60)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Apple Watch Series 9 - 45mm") {
    StepperWatchView(count: .constant(0))
}
