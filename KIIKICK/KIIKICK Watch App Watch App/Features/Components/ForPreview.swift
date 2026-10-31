//
//  ForPreview.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 10/31/26.
//

import SwiftUI

struct ForPreview: View {
    
    @State private var selection: WatchComponents = .btn

    enum WatchComponents {
        case btn, cta, progress, stepper, sub
    }
    
    var body: some View {
        TabView(selection: $selection) {
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 119)
                Spacer()
                CtaWatchView(text: "경기 시작", type: .primary, action: {})
            }
            VStack {
                Text("포지션을 선택하세요")
                    .font(Font.body4R)
                HStack(spacing: 8) {
                    BtnSelectionView { }
                    BtnSelectionView { }
                    BtnSelectionView { }
                }
                HStack(spacing: 8) {
                    BtnSelectionView { }
                    BtnSelectionView { }
                    BtnSelectionView { }
                }
                HStack(spacing: 8) {
                    BtnSelectionView { }
                    BtnSelectionView { }
                    BtnSelectionView { }
                }
                BtnSelectionView { }
            }
            CtaWatchView(text: "경기 시작", type: .primary, action: {})
            CtaWatchView(text: "경기 종료", type: .destructive, action: {})
            ProgressWatchButton()
            StepperViewWatch()
            SubWatchView { }
        }
    }
}

#Preview {
    ForPreview()
}
