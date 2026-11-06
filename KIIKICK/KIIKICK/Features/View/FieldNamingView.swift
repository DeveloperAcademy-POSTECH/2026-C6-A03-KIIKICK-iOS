//
//  FieldNamingView.swift
//  KIIKICK
//
//  Figma node 256:1094 "newfield_03"(경기장 이름 입력) / 259:1467 "Alert"(등록 취소 확인) — iOS 화면
//
//  "selected field" 썸네일(256:1132)은 보정된 직사각형 영역을 실제 지도 스냅샷으로
//  렌더링해서 보여준다(MKMapSnapshotter). 스냅샷 위에 보정된 운동장 경계선을 겹쳐 그려서,
//  사용자가 찍은 원본 핀이 아니라 실제로 저장될 직사각형을 미리 보여준다.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct FieldNamingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 사용자가 찍은 순서 그대로의 원본 4핀. 보정된 직사각형은 이 값으로부터 계산한다.
    let rawCoordinates: [CLLocationCoordinate2D]
    var onFinish: () -> Void = {}

    @State private var fieldName: String = ""
    @State private var isPresentingLeaveConfirm = false
    @State private var snapshotImage: UIImage?

    private let thumbnailSize = CGSize(width: 354, height: 138)

    private var correctedCoordinates: [CLLocationCoordinate2D] {
        FieldRectangleCorrector.correct(rawCorners: rawCoordinates)
    }

    private var canSave: Bool {
        !fieldName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 28) {
            thumbnail

            KiikickTextField(
                text: $fieldName,
                placeholder: "경기장 이름을 지어주세요",
                state: fieldName.isEmpty ? .default : .completed,
                maxCount: 18
            )

            Spacer()

            CtaView(text: "등록 완료", type: .primary, size: .large, isActive: canSave) {
                save()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("경기장 등록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { handleBack() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .alert("경기장 등록을 취소할까요?", isPresented: $isPresentingLeaveConfirm) {
            Button("계속 등록", role: .cancel) {}
            Button("등록 취소", role: .destructive) { onFinish() }
        } message: {
            Text("입력한 내용은 저장되지 않아요.")
        }
        .task {
            snapshotImage = await Self.renderSnapshot(for: correctedCoordinates, size: thumbnailSize)
        }
    }

    private var thumbnail: some View {
        ZStack {
            if let snapshotImage {
                Image(uiImage: snapshotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray800
                ProgressView()
                    .tint(.mint500)
            }
        }
        .frame(height: 138)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(24)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 12))
    }

    private func handleBack() {
        if canSave {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard rawCoordinates.count == 4 else { return }
        let corrected = correctedCoordinates
        let field = Field(
            name: fieldName,
            cornerA: FieldCorner(latitude: corrected[0].latitude, longitude: corrected[0].longitude),
            cornerB: FieldCorner(latitude: corrected[1].latitude, longitude: corrected[1].longitude),
            cornerC: FieldCorner(latitude: corrected[2].latitude, longitude: corrected[2].longitude),
            cornerD: FieldCorner(latitude: corrected[3].latitude, longitude: corrected[3].longitude),
            rawCornerA: FieldCorner(latitude: rawCoordinates[0].latitude, longitude: rawCoordinates[0].longitude),
            rawCornerB: FieldCorner(latitude: rawCoordinates[1].latitude, longitude: rawCoordinates[1].longitude),
            rawCornerC: FieldCorner(latitude: rawCoordinates[2].latitude, longitude: rawCoordinates[2].longitude),
            rawCornerD: FieldCorner(latitude: rawCoordinates[3].latitude, longitude: rawCoordinates[3].longitude)
        )
        modelContext.insert(field)
        try? modelContext.save()
        onFinish()
    }

    /// 네 꼭짓점이 모두 보이는 영역을 지도 스냅샷으로 렌더링하고, 그 위에 운동장 경계선을
    /// 겹쳐 그린다.
    private static func renderSnapshot(for coordinates: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        guard coordinates.count == 4 else { return nil }

        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let paddingFactor = 2.2
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * paddingFactor, 0.0012),
            longitudeDelta: max((lons.max()! - lons.min()!) * paddingFactor, 0.0012)
        )

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: center, span: span)
        options.size = size
        options.mapType = .satellite
        options.showsBuildings = true

        guard let snapshot = try? await MKMapSnapshotter(options: options).start() else { return nil }

        return UIGraphicsImageRenderer(size: size).image { _ in
            snapshot.image.draw(at: .zero)

            let points = coordinates.map { snapshot.point(for: $0) }
            guard let first = points.first else { return }
            let path = UIBezierPath()
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.close()

            UIColor.white.withAlphaComponent(0.2).setFill()
            path.fill()
            UIColor.white.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }
}

#Preview {
    NavigationStack {
        FieldNamingView(rawCoordinates: [
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.0),
        ])
    }
}
