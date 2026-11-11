import SwiftUI

struct TrackingMapPager: View {
    private enum Page: Hashable {
        case heatmap, sprint
        #if DEBUG
        case satellite
        #endif
    }

    let field: Field?
    let points: [TrackPoint]
    var isAttackDirectionReversed = false
    var events: [AnalysisMatchEvent] = []

    @State private var selection: Page = .heatmap

    var body: some View {
        Group {
            if let field {
                TabView(selection: $selection) {
                    FieldHeatmapView(field: field, points: points, isAttackDirectionReversed: isAttackDirectionReversed)
                        .overlay(TrackingMapEventsView(events: events, isAttackDirectionReversed: isAttackDirectionReversed))
                        .padding(.bottom, 28)
                        .accessibilityLabel("히트맵")
                        .tag(Page.heatmap)
                    SprintMapView(field: field, points: points, isAttackDirectionReversed: isAttackDirectionReversed)
                        .overlay(TrackingMapEventsView(events: events, isAttackDirectionReversed: isAttackDirectionReversed))
                        .padding(.bottom, 28)
                        .accessibilityLabel("스프린트 맵, 시속 \(Int(SprintDetector.defaultSpeedThresholdKmh))킬로미터 초과, 이동거리 10미터 이상 구간")
                        .tag(Page.sprint)
                    #if DEBUG
                    // TabView는 인접 페이지를 미리 구성한다. 지도는 실제 선택 시에만 생성한다.
                    Group {
                        if selection == .satellite {
                            TrackingSatelliteDebugView(field: field, points: points)
                        } else {
                            Color.clear
                        }
                    }
                    .padding(.bottom, 28)
                    .accessibilityLabel("위성사진과 원본 GPS 포인트")
                    .tag(Page.satellite)
                    #endif
                }
                // DESIGN-GAP: 페이지 컨트롤은 시스템 기본 표현. Figma의 민트색 도트와 색상 차이가 있다.
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray850)
                    .overlay {
                        VStack(spacing: 12) {
                            Text("운동장을 지정하면 맵을 볼 수 있어요")
                                .font(.caption1M)
                                .foregroundStyle(.colorTextSecondary)
                        }
                    }
            }
        }
    }
}
