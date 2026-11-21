import SwiftUI

struct MatchCommentsSheet: View {
    @Bindable var model: MatchCommentsModel
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: 20) {
            VStack { }.frame(height: 4)
            Text("댓글 \(model.commentCount)\(model.hasNext ? "+" : "")")
                .font(.title3M)
                .foregroundStyle(.colorTextPrimary)
                .padding(.top, 8)
                .padding(.bottom, 12)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(model.displayedComments) { comment in
                        CommentThreadView(
                            comment: comment,
                            allowsReplies: isExpanded,
                            onReply: model.beginReply(to:)
                        )
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
                if let replyTarget = model.replyTarget {
                    HStack(spacing: 8) {
                        Text("\(replyTarget.authorNickname)님에게 답글")
                            .font(.caption1M)
                            .foregroundStyle(.colorTextSecondary)
                        Spacer()
                        Button("취소", action: model.cancelReply)
                            .font(.caption1M)
                            .foregroundStyle(.colorTextSecondary)
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                }
                CommentComposerView(text: $model.draft, isActive: model.canSend, isSubmitting: model.isSending) {
                    Task { await model.send() }
                }
            }
        }
        .dismissKeyboardOnTap()
        .task { await model.loadInitial() }
    }
}
