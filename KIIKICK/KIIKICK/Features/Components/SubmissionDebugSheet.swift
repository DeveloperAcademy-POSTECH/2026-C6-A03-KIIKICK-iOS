//
//  SubmissionDebugSheet.swift
//  KIIKICK
//
//  이슈 #96: "분석 다시 보기"가 보낸 workout-submissions 요청과 서버 응답을 기기에서
//  그대로 보기 위한 디버깅용 팝업. 재전송을 서버가 어떻게 처리하는지(갱신 / 409 /
//  쿼터 중복 생성) Console 없이 확인하려고 만들었다 — 사용자용 화면이 아니라서
//  디자인 토큰만 따르고 Figma 대응 노드는 없다.
//
//  .sheet가 아니라 오버레이인 이유: AnalysisDetailView는 댓글 바텀시트를
//  `sheet(isPresented: .constant(true))`로 항상 띄워 두는데, 한 뷰는 시트를 하나만
//  표시할 수 있어서 두 번째 .sheet는 조용히 무시된다. 오버레이는 그 제약을 받지 않는다.
//

import SwiftUI
import UIKit

struct SubmissionDebugReport: Identifiable {
    let id = UUID()
    let title: String
    let lines: [String]

    var text: String { lines.joined(separator: "\n") }
}

struct SubmissionDebugPopup: View {
    let report: SubmissionDebugReport
    let onClose: () -> Void
    @State private var didCopy = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack {
                    Text(report.title)
                        .font(.label1M)
                        .foregroundStyle(.colorTextPrimary)
                    Spacer()
                    Button(didCopy ? "복사됨" : "복사") {
                        UIPasteboard.general.string = report.text
                        didCopy = true
                    }
                    .font(.caption1M)
                    .foregroundStyle(.mint500)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().overlay(Color.gray800)

                ScrollView {
                    Text(report.text)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.colorTextPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 360)

                Divider().overlay(Color.gray800)

                Button(action: onClose) {
                    Text("닫기")
                        .font(.label1M)
                        .foregroundStyle(.colorTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .background(Color.colorSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
            // 접힌 댓글 시트가 아래를 덮으므로 그만큼 띄운다.
            .padding(.bottom, 90)
        }
    }
}

#if DEBUG
#Preview {
    Color.gray950.ignoresSafeArea()
        .overlay {
            SubmissionDebugPopup(
                report: SubmissionDebugReport(
                    title: "분석 다시 보내기",
                    lines: [
                        "POST /matches/8f14e45f-ea8d-4b2c-9a7e-000000000096/workout-submissions",
                        "Idempotency-Key: 3F2504E0-4F89-41D3-9A0C-0305E82C3301",
                        "[보낸 요청]",
                        "matchId: 8F14E45F-EA8D-4B2C-9A7E-000000000096",
                        "If-Match: 7",
                        "쿼터[0] quarterId=... position=CM points=1203 hr=240 field=포스텍 대운동장",
                        "[응답] 성공 — matchId=... quarterCount=2 matchVersion=8",
                    ]
                ),
                onClose: {}
            )
        }
}
#endif
