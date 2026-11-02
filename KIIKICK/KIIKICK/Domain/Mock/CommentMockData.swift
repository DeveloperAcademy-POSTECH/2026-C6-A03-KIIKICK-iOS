//
//  CommentMockData.swift
//  KIIKICK
//
//  이슈 #17 범위(목업 데이터로 뷰만 구현)라 실제 댓글 저장/서버 연동은 하지 않는다.
//

import Foundation

enum CommentMockData {
    static let threads: [Comment] = [
        Comment(
            authorNickname: "갱아",
            content: "이번 경기 스프린트 진짜 많이 늘었다 ㅋㅋ",
            timestamp: "3시간 전",
            replies: [
                CommentReply(authorNickname: "루디", content: "인정 ㅋㅋㅋ 다음엔 나도 끼워줘", timestamp: "2시간 전"),
            ]
        ),
        Comment(
            authorNickname: "곤",
            content: "히트맵 보니까 왼쪽 사이드만 계속 뛰었네 ㅋㅋ",
            timestamp: "1시간 전"
        ),
    ]
}
