//
//  ShareImageView.swift
//  KIIKICK
//
//  Figma node 750:5505 "공유하기 세로형" / 750:5684 "공유하기 가로형"(이슈 #43) —
//  쿼터 하나의 핵심 스탯 + 히트맵을 이미지로 내보내 사진 앱에 저장하는 화면.
//  세로형/가로형 두 레이아웃(ShareCardView)을 TabView 페이지로 넘겨보다가, 다운로드
//  버튼을 누르면 "지금 보고 있는" 카드를 ImageRenderer로 캡처해서 저장한다.
//
//  AnalysisDetailView의 "내 플레이 공유하기" 버튼에서 들어온다.
//

import Photos
import SwiftUI

struct ShareImageView: View {
    @Environment(\.dismiss) private var dismiss

    let keyStats: [AnalysisStat]

    @State private var selectedLayout = 0
    @State private var saveState: SaveState = .idle

    private enum SaveState: Equatable {
        case idle, saving, success, failure(String)
    }

    var body: some View {
        VStack(spacing: 40) {
            TabView(selection: $selectedLayout) {
                ShareCardView(keyStats: keyStats, orientation: .vertical)
                    .tag(0)
                ShareCardView(keyStats: keyStats, orientation: .horizontal)
                    .tag(1)
            }
            .tabViewStyle(.page)
            .frame(height: 460)

            VStack(spacing: 16) {
                Text(statusText)
                    .font(.title2SB)
                    .foregroundStyle(.colorTextPrimary)

                Button(action: save) {
                    Image("ic_download")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.colorTextPrimary)
                        .padding(16)
                        .background(Color.gray800, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(saveState == .saving)
            }
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.backward") }
            }
            ToolbarItem(placement: .principal) {
                Text("공유하기")
                    .font(.head3B)
                    .foregroundStyle(.colorTextPrimary)
            }
        }
    }

    private var statusText: String {
        switch saveState {
        case .idle, .saving: "이미지 저장"
        case .success: "사진 앱에 저장됐어요"
        case .failure(let message): message
        }
    }

    @MainActor
    private func save() {
        let orientation: ShareCardView.Orientation = selectedLayout == 0 ? .vertical : .horizontal
        let renderer = ImageRenderer(content: ShareCardView(keyStats: keyStats, orientation: orientation))
        renderer.scale = UIScreen.main.scale
        // 카드 자체가 배경을 안 칠해서 투명하다 — isOpaque를 꺼야 알파 채널이 살아남는다.
        renderer.isOpaque = false

        // PHAssetChangeRequest.creationRequestForAsset(from:)은 UIImage를 JPEG로
        // 변환해버려서 투명도가 날아간다 — PNG Data를 직접 만들어 addResource로 넣어야
        // 투명 배경이 사진 앱에도 그대로 저장된다.
        guard let uiImage = renderer.uiImage, let pngData = uiImage.pngData() else {
            saveState = .failure("이미지를 만들지 못했어요")
            return
        }

        saveState = .saving
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveState = .failure("사진 접근 권한이 필요해요")
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: pngData, options: nil)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        saveState = success ? .success : .failure(error?.localizedDescription ?? "저장 실패")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShareImageView(keyStats: AnalysisMockData.entries[0].detail.keyStats)
    }
}
