//
//  FriendMockData.swift
//  KIIKICK
//
//  이슈 #14 NotToDo(API 연동, 데이터 저장) 범위 밖이라 화면 확인용 목업 데이터만 둔다.
//

import Foundation

enum FriendMockData {
    static let myFriends: [UserProfile] = [
        UserProfile(nickname: "갱아", status: .friend),
        UserProfile(nickname: "루디", status: .friend),
        UserProfile(nickname: "곤", status: .friend),
        UserProfile(nickname: "애셔", status: .friend),
    ]

    /// 친구 검색 화면에서 검색 대상이 되는 전체 사용자 풀. 이미 친구인 사용자도 검색되어야
    /// 하므로 `myFriends`를 포함한다.
    static let searchPool: [UserProfile] = myFriends + [
        UserProfile(nickname: "조승연", status: .requestSent),
        UserProfile(nickname: "조승연아", status: .none),
        UserProfile(nickname: "조승연이", status: .none),
    ]
}
