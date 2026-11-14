//
//  AnalysisMessagePopup.swift
//  KIIKICK
//
//  이슈 #96: AnalysisDetailView의 알림용 팝업.
//
//  .alert이 아니라 오버레이인 이유: 이 화면은 댓글 바텀시트를
//  `sheet(isPresented: .constant(true))`로 항상 띄워 두는데, 한 뷰는 동시에 하나만
//  표시할 수 있어서 그 위에서 요청한 alert/confirmationDialog/sheet는 조용히 무시된다.
//  그래서 운동장 변경이 실패해도 아무 메시지가 뜨지 않아 "변경이 안 된다"로 보였다.
//

import SwiftUI

struct AnalysisMessagePopup: View {
    let title: String
    let message: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 16) {
                Text(title)
                    .font(.label1M)
                    .foregroundStyle(.colorTextPrimary)
                    .multilineTextAlignment(.center)
                ScrollView {
                    Text(message)
                        .font(.body4R)
                        .foregroundStyle(.colorTextSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                CtaView(text: "확인", type: .primary, size: .large, action: onClose)
            }
            .padding(20)
            .background(Color.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)
            // 접힌 댓글 시트가 화면 아래를 덮으므로 그만큼 띄운다.
            .padding(.bottom, 90)
        }
    }
}

#if DEBUG
#Preview {
    Color.gray950.ignoresSafeArea()
        .overlay {
            AnalysisMessagePopup(
                title: "서버에 반영하지 못했어요",
                message: "운동장은 이 기기에 저장됐어요. 네트워크가 돌아오면 다시 시도해주세요.\ninvalidHttpStatusCode(412, …)",
                onClose: {}
            )
        }
}
#endif
