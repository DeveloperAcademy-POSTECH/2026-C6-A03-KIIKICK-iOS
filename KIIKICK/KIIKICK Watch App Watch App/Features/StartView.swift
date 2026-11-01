//
//  StartView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct StartView: View {
    
    var action: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130)
                Spacer()
                CtaWatchView(text: "경기 시작", type: .primary, action: {action()})
                    .frame(maxWidth: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(12)
        .ignoresSafeArea()
    }
}
