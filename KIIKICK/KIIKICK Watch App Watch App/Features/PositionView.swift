//
//  PositionView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct PositionView: View {

    var action: (Position) -> Void

    var body: some View {
        VStack {
            Text("포지션을 선택하세요")
                .font(Font.body4R)
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lw.uppercased) { action(.lw) }
                BtnSelectionView(text: Position.st.uppercased) { action(.st) }
                BtnSelectionView(text: Position.rw.uppercased) { action(.rw) }
            }
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lm.uppercased) { action(.lm) }
                BtnSelectionView(text: Position.cm.uppercased) { action(.cm) }
                BtnSelectionView(text: Position.rm.uppercased) { action(.rm) }
            }
            HStack(spacing: 8) {
                BtnSelectionView(text: Position.lb.uppercased) { action(.lb) }
                BtnSelectionView(text: Position.cb.uppercased) { action(.cb) }
                BtnSelectionView(text: Position.rb.uppercased) { action(.rb) }
            }
            BtnSelectionView(text: Position.gk.uppercased) { action(.gk) }
        }
    }
}
