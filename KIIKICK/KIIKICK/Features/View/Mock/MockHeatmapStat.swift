import SwiftUI

struct MockHeatmapStat: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.colorTextSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.headline)
                    .foregroundStyle(.colorTextPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.colorTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray850, in: .rect(cornerRadius: 12))
    }
}
