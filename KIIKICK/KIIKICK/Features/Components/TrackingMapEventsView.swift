import SwiftUI

struct TrackingMapEventsView: View {
    let events: [AnalysisMatchEvent]
    let isAttackDirectionReversed: Bool

    var body: some View {
        GeometryReader { geometry in
            ForEach(events) { event in
                Image(event.type.iconName)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .position(position(for: event, size: geometry.size))
                    .accessibilityLabel("\(event.type.label), \(event.timeText)")
            }
        }
        .allowsHitTesting(false)
    }

    private func position(for event: AnalysisMatchEvent, size: CGSize) -> CGPoint {
        let point = AttackDirectionTransform(isReversed: isAttackDirectionReversed)
            .apply(to: CGPoint(x: event.position.x, y: event.position.y))
        return FieldArtworkLayout.pixel(for: point, in: size)
    }
}
