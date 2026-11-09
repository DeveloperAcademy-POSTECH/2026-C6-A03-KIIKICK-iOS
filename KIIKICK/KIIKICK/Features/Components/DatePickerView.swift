//
//  DatePickerView.swift
//  KIIKICK
//
//  Figma node 331:2707 "DatePicker"(기본) / 493:2997 "date picker"(버그 재현용 인스턴스,
//  연도 숫자 짤림 — 이슈 #43) — Assets&Components 페이지.
//
//  Figma 목업은 펼쳐진 상태를 "선택값 위에 이전 값 하나"만 보여주는 정적 스냅샷으로
//  표현하지만, 실제 동작하는 선택기가 되려면 스크롤이 필요하다. 그 부분은 SwiftUI
//  네이티브 `.wheel` Picker로 구현했다(DESIGN-GAP: 스크롤 동작 자체는 Figma에 명시되지 않음).
//
//  이슈 #43 수정 2가지:
//  1. 연도 숫자 짤림 — 휠 Picker 행에 명시적 폰트를 안 줘서 시스템 기본 폰트/크기로
//     그려졌고, "2026년" 같은 5글자가 기존 84pt 폭에서 잘렸다. 폭을 100pt로 늘리고
//     label1_m을 명시했다.
//  2. "기록이 있는 연도/월만 표시"(493:2997 annotation) — yearRange를 통째로 허용하던
//     걸 버리고, 호출부가 실제 기록이 있는 (연도,월) 조합만 availableYearMonths로
//     넘기게 바꿨다. 연도를 바꿨을 때 그 연도에 없는 월이 선택돼 있으면 가능한 월
//     중 첫 번째로 스냅한다.
//

import SwiftUI

struct YearMonth: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

struct DatePickerView: View {
    @Binding var year: Int
    @Binding var month: Int
    /// 기록이 있는 (연도, 월) 조합만. 비어 있으면 피커를 펼쳐도 선택할 게 없다.
    let availableYearMonths: [YearMonth]

    @State private var isExpanded = false

    private var availableYears: [Int] {
        Array(Set(availableYearMonths.map(\.year))).sorted()
    }

    private func availableMonths(for year: Int) -> [Int] {
        availableYearMonths.filter { $0.year == year }.map(\.month).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(verbatim: "\(year)년 \(month)월")
                        .font(.head2SB)
                        .foregroundStyle(.gray50)
                    Image(isExpanded ? "ic_arrow_up" : "ic_chevron_down")
                        .resizable()
                        .foregroundStyle(.gray50)
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(.plain)
            .disabled(availableYearMonths.isEmpty)

            if isExpanded {
                HStack(spacing: 16) {
                    Picker("년", selection: $year) {
                        ForEach(availableYears, id: \.self) { y in
                            Text(verbatim: "\(y)년")
                                .font(.label1M)
                                .tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    Picker("월", selection: $month) {
                        ForEach(availableMonths(for: year), id: \.self) { m in
                            Text(verbatim: "\(m)월")
                                .font(.label1M)
                                .tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 72)
                }
                .frame(height: 120)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.mint700, lineWidth: 1)
                )
                .onChange(of: year) { _, newYear in
                    let months = availableMonths(for: newYear)
                    if !months.contains(month) {
                        month = months.first ?? month
                    }
                }
            }
        }
    }
}

#Preview {
    DatePickerView(
        year: .constant(2026), month: .constant(10),
        availableYearMonths: [
            YearMonth(year: 2025, month: 9),
            YearMonth(year: 2026, month: 10),
            YearMonth(year: 2026, month: 11),
        ]
    )
    .padding()
    .background(Color.gray950)
}
