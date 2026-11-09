//
//  PerformanceTrendsView.swift
//  KIIKICK
//
//  Figma node 259:3591 "Performance Trends" (Assets&Components 페이지)
//
//  Figma 컴포넌트 설명: "Pinch only: minimum 4 quarters, default 8, maximum all records.
//  Horizontal pan; point tap selects locally. No detail navigation. Samples are synthetic."
//  DESIGN-GAP: 핀치/팬/포인트 탭 상호작용은 아직 구현하지 않았다 — 정적 데이터 기준
//  라인차트 렌더링까지만. 제스처는 별도 작업으로 분리.
//
//  홈 화면에서 누적 OVR 또는 쿼터별 속도·거리·칼로리 데이터를 전달한다.
//

import SwiftUI
import Charts

enum PerformanceMetric: String, CaseIterable {
    case overall = "오버롤"
    case speed = "최고속도"
    case distance = "이동거리"
    case calories = "칼로리"
}

struct PerformanceTrendPoint: Identifiable {
    let id = UUID()
    let quarterIndex: Int
    let value: Double
}

struct PerformanceTrendsView: View {
    @Binding var selectedMetric: PerformanceMetric
    let points: [PerformanceTrendPoint]
    let unit: String
    let dateLabel: String
    let yAxisValues: [Double]
    /// 0...1 범위. 전체 기록 중 현재 보이는 구간의 시작 비율/너비 비율(읽기 전용 표시용).
    var visibleRangeStart: Double = 0
    var visibleRangeWidth: Double = 1

    private var selectedValueText: String {
        guard let last = points.last else { return "-" }
        return unit == "kcal" ? String(format: "%.0f", last.value) : String(format: "%.2f", last.value)
    }

    var body: some View {
        VStack(spacing: 12) {
            metricTabs
            header
            chart
            rangeIndicator
        }
        .padding(16)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 16))
    }

    private var metricTabs: some View {
        HStack(spacing: 4) {
            ForEach(PerformanceMetric.allCases, id: \.self) { metric in
                Button {
                    selectedMetric = metric
                } label: {
                    Text(metric.rawValue)
                        .font(.label3M)
                        .foregroundStyle(metric == selectedMetric ? .gray50 : .gray400)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            metric == selectedMetric ? Color.gray850 : .clear,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.gray950, in: RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(selectedValueText)
                    .font(.display1SB)
                    .foregroundStyle(.gray50)
                Text(unit)
                    .font(.label3M)
                    .foregroundStyle(.gray400)
            }
            Spacer()
            Text(dateLabel)
                .font(.body4R)
                .foregroundStyle(.gray50)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("쿼터", point.quarterIndex), y: .value("값", point.value))
                    .foregroundStyle(.mint500)
                    .interpolationMethod(.linear)
                PointMark(x: .value("쿼터", point.quarterIndex), y: .value("값", point.value))
                    .foregroundStyle(.mint500)
                    .symbolSize(point.id == points.last?.id ? 60 : 12)
            }
            if let last = points.last {
                RuleMark(x: .value("쿼터", last.quarterIndex))
                    .foregroundStyle(Color.mint500.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine().foregroundStyle(Color.gray800)
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(verbatim: "\(Int(d))")
                            .font(.caption2SB)
                            .foregroundStyle(.gray400)
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Text(unit)
                .font(.caption2SB)
                .foregroundStyle(.gray400)
        }
        .frame(height: 150)
    }

    private var rangeIndicator: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray800)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.mint700)
                    .frame(width: geo.size.width * visibleRangeWidth)
                    .offset(x: geo.size.width * visibleRangeStart)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    PerformanceTrendsView(
        selectedMetric: .constant(.speed),
        points: (0..<8).map { PerformanceTrendPoint(quarterIndex: $0, value: Double.random(in: 15...25)) },
        unit: "km/h",
        dateLabel: "10월 28일 · Q4",
        yAxisValues: [0, 10, 20, 30],
        visibleRangeStart: 0.666,
        visibleRangeWidth: 0.333
    )
    .padding()
    .background(Color.gray950)
}
