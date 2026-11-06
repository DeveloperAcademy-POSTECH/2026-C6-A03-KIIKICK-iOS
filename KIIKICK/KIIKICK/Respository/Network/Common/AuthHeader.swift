//
//  AuthHeader.swift
//  KIIKICK
//
//  로그인 성공 시 UserSession에 저장된 accessToken을 Authorization 헤더로 붙인다.
//  friends/match/quarter 등 다른 도메인 Endpoint들은 각자 파일에 "Authorization 주입이
//  아직 없다"는 DESIGN-GAP 주석만 남겨뒀다 — 그 도메인들을 이 헤더를 쓰도록 바꾸는 건
//  이번 범위 밖이고, Auth 쪽 구현을 기점으로 넓혀갈 부분이다.
//

import Foundation

func bearerHeaders() -> [String: String] {
    guard let token = UserSession.token else { return [:] }
    return ["Authorization": "Bearer \(token)"]
}
