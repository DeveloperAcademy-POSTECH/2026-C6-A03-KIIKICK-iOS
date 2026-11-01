//
//  PositionView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct PositionView: View {
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            Text("포지션을 선택하세요")
                .font(Font.body4R)
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lw.uppercased) { action() }
                BtnSelectionView(text: Position.st.uppercased) { action() }
                BtnSelectionView(text: Position.rw.uppercased) { action() }
            }
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lm.uppercased) { action() }
                BtnSelectionView(text: Position.cm.uppercased) { action() }
                BtnSelectionView(text: Position.rm.uppercased) { action() }
            }
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lb.uppercased) { action() }
                BtnSelectionView(text: Position.cb.uppercased) { action() }
                BtnSelectionView(text: Position.rb.uppercased) { action() }
            }
            BtnSelectionView(text: Position.gk.uppercased) { }
        }
    }
}
