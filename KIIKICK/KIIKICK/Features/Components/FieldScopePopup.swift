//
//  FieldScopePopup.swift
//  KIIKICK
//
//  이슈 #96: 고른 운동장을 "모든 쿼터"에 적용할지 "이 쿼터만" 적용할지 묻는 팝업.
//
//  confirmationDialog가 아니라 오버레이인 이유: AnalysisDetailView는 댓글 바텀시트를
//  `sheet(isPresented: .constant(true))`로 항상 띄워 두는데, 한 뷰는 동시에 하나만
//  표시할 수 있어서 그 위에서 요청한 다이얼로그/시트는 조용히 무시된다. 실제로 운동장을
//  골라도 아무 일도 일어나지 않는 증상이 났다. 오버레이는 그 제약을 받지 않는다.
//

import SwiftUI

struct FieldScopePopup: View {
    let fieldName: String
    let quarterNumber: Int?
    let onAllQuarters: () -> Void
    let onCurrentQuarter: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("‘\(fieldName)’을 어디에 적용할까요?")
                        .font(.label1M)
                        .foregroundStyle(.colorTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("히트맵은 바로 다시 그려지고, 서버에도 반영됩니다.")
                        .font(.body4R)
                        .foregroundStyle(.colorTextSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    CtaView(text: "모든 쿼터에 적용", type: .primary, size: .large, action: onAllQuarters)
                    if let quarterNumber {
                        CtaView(text: "\(quarterNumber)쿼터만 적용", type: .secondary, size: .large, action: onCurrentQuarter)
                    }
                    Button(action: onCancel) {
                        Text("취소")
                            .font(.label1M)
                            .foregroundStyle(.colorTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
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
            FieldScopePopup(
                fieldName: "포스텍 대운동장", quarterNumber: 2,
                onAllQuarters: {}, onCurrentQuarter: {}, onCancel: {}
            )
        }
}
#endif
