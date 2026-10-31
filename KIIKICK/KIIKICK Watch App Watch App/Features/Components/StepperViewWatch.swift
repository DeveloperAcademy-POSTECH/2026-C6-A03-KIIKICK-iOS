//
//  StepperView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct StepperViewWatch: View {
    
    @State var count: Int = 0

    var body: some View {
        HStack(spacing: 25) {
            Button {
                count -= 1
            } label: {
                ZStack {
                    Capsule()
                        .fill(Color("Gray400"))
                    Image(systemName: "minus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color("Gray50"))
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
                        .fill(Color("Mint500"))
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color("Gray50"))
                }
                .frame(width: 48, height: 60)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Apple Watch Series 9 - 45mm") {
    StepperViewWatch()
}
