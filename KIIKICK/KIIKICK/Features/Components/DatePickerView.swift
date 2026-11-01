//
//  DatePickerView.swift
//  KIIKICK
//
//  Figma node 331:2707 "DatePicker" (Assets&Components 페이지)
//
//  Figma 목업은 펼쳐진 상태를 "선택값 위에 이전 값 하나"만 보여주는 정적 스냅샷으로
//  표현하지만, 실제 동작하는 선택기가 되려면 스크롤이 필요하다. 그 부분은 SwiftUI
//  네이티브 `.wheel` Picker로 구현했다(DESIGN-GAP: 스크롤 동작 자체는 Figma에 명시되지 않음).
//

import SwiftUI

struct DatePickerView: View {
    @Binding var year: Int
    @Binding var month: Int
    var yearRange: ClosedRange<Int> = 2020...2030

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(verbatim: "\(year)년 \(month)월")
                        .font(.head2SB)
                        .foregroundStyle(.gray50)
                    Image("ic_chevron_down")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(spacing: 16) {
                    Picker("년", selection: $year) {
                        ForEach(Array(yearRange), id: \.self) { y in
                            Text(verbatim: "\(y)년").tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 84)

                    Picker("월", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(verbatim: "\(m)월").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 63)
                }
                .frame(height: 120)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.mint700, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    DatePickerView(year: .constant(2026), month: .constant(10))
        .padding()
        .background(Color.gray950)
}
