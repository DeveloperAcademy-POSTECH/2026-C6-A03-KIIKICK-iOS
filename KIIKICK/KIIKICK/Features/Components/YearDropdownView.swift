//
//  YearDropdownView.swift
//  KIIKICK
//
//  Figma node 535:3327 "dropdown_year" (Assets&Components 페이지) — 연도만 고르는 축약형
//  드롭다운. 연·월을 같이 고르는 DatePickerView와는 쓰임이 다르다.
//
//  DESIGN-GAP: Figma 목업은 펼친 상태를 "선택값 위에 이전 값 하나"만 보여주는 정적
//  스냅샷으로 표현하지만, 실제 스크롤이 필요해서 DatePickerView와 동일하게 네이티브
//  `.wheel` Picker로 구현했다.
//

import SwiftUI

struct YearDropdownView: View {
    @Binding var year: Int
    var yearRange: ClosedRange<Int> = 2020...2030

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(verbatim: "\(year)")
                        .font(.body4R)
                        .foregroundStyle(.gray50)
                    Image("ic_chevron_down")
                        .resizable()
                        .foregroundStyle(.gray50)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .padding(.vertical, 4)
                .background(Color.gray800, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray700, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                Picker("년", selection: $year) {
                    ForEach(Array(yearRange), id: \.self) { y in
                        Text(verbatim: "\(y)년").tag(y)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 124, height: 98)
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
    YearDropdownView(year: .constant(2026))
        .padding()
        .background(Color.gray950)
}
