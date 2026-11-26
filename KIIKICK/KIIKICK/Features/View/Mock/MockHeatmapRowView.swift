import SwiftUI

struct MockHeatmapRowView: View {
    let player: MockHeatmapPlayer

    var body: some View {
        HStack(spacing: 14) {
            MockHeatmapFieldView(points: player.allPoints)
                .frame(width: 138)

            VStack(alignment: .leading, spacing: 6) {
                Text(player.displayName)
                    .font(.headline)
                    .foregroundStyle(.colorTextPrimary)
                Text(player.role)
                    .font(.subheadline)
                    .foregroundStyle(.colorTextSecondary)
                Text("평균 \(player.averageSpeedKmh, format: .number.precision(.fractionLength(1))) km/h")
                    .font(.caption)
                    .foregroundStyle(.colorTextSecondary)
                Text("최고 \(player.maxSpeedKmh, format: .number.precision(.fractionLength(1))) km/h")
                    .font(.caption)
                    .foregroundStyle(.colorTextSecondary)
            }
        }
        .padding(.vertical, 6)
    }
}
