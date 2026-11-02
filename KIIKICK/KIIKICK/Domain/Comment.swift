//
//  Comment.swift
//  KIIKICK
//
//  Figma node 371:2951 "comment" 안의 comment_thread 컴포넌트(이슈 #17, 목업 전용).
//  대댓글은 한 단계만 있어서(대댓글의 대댓글 없음) nested array로 충분하다.
//

import Foundation

struct CommentReply: Identifiable, Hashable {
    let id: UUID
    let authorNickname: String
    let avatarImageName: String?
    let content: String
    let timestamp: String

    init(id: UUID = UUID(), authorNickname: String, avatarImageName: String? = nil, content: String, timestamp: String) {
        self.id = id
        self.authorNickname = authorNickname
        self.avatarImageName = avatarImageName
        self.content = content
        self.timestamp = timestamp
    }
}

struct Comment: Identifiable, Hashable {
    let id: UUID
    let authorNickname: String
    let avatarImageName: String?
    let content: String
    let timestamp: String
    let replies: [CommentReply]

    init(
        id: UUID = UUID(),
        authorNickname: String,
        avatarImageName: String? = nil,
        content: String,
        timestamp: String,
        replies: [CommentReply] = []
    ) {
        self.id = id
        self.authorNickname = authorNickname
        self.avatarImageName = avatarImageName
        self.content = content
        self.timestamp = timestamp
        self.replies = replies
    }
}
