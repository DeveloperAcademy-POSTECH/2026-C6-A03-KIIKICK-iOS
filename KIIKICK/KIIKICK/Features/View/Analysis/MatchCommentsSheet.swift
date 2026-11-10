import SwiftUI

struct MatchCommentsSheet: View {
    @Bindable var model: MatchCommentsModel
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            VStack { }.frame(height: 4)
            Text("댓글 \(model.comments.count)\(model.hasNext ? "+" : "")")
                .font(.title3M)
                .foregroundStyle(.colorTextPrimary)
                .padding(.top, 8)
                .padding(.bottom, 12)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(model.displayedComments) { comment in
                        // DESIGN-GAP: 대댓글 API가 없어 서버 댓글에는 동작하지 않는 답글 버튼을 표시하지 않는다.
                        CommentThreadView(comment: comment, allowsReplies: false)
                    }
                    if model.isLoading { ProgressView() }
                    if model.hasNext || model.errorMessage != nil {
                        CtaView(text: model.errorMessage == nil ? "댓글 더 보기" : "다시 불러오기", type: .sub,
                            size: .small, isActive: !model.isLoading) { Task { await model.loadMore() } }
                    }
                }
            }
            .padding(.horizontal, 24)
            .scrollDismissesKeyboard(.interactively)
            if let message = model.validationMessage ?? model.errorMessage {
                Text(message).textStyle(.caption1M).foregroundStyle(.red500).padding(.horizontal, 24)
            }
            if isExpanded {
                CommentComposerView(text: $model.draft, isActive: model.canSend, isSubmitting: model.isSending) {
                    Task { await model.send() }
                }
            }
        }
        .dismissKeyboardOnTap()
        .task { await model.loadInitial() }
    }
}
