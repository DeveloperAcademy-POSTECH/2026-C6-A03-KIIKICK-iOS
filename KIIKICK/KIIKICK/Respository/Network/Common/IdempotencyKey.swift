//
//  IdempotencyKey.swift
//  KIIKICK
//
//  백엔드 docs/api/common.md: 프로필·친구·알림·기기·경기장 변경과 경기 생성 등 "쓰기"
//  요청은 Idempotency-Key 헤더가 필수다. 문서는 "같은 의도의 재시도는 같은 키 유지"를
//  권장하지만, 키를 어디에 얼마나 영속화할지는 아직 정책 미확정(P10/P11)이라 매 호출마다
//  새 UUID를 발급한다 — 헤더 요구사항은 충족하지만, 재시도 시 멱등 재생 이점은 아직 없다.
//

import Foundation

func idempotencyHeaders() -> [String: String] {
    idempotencyHeaders(UUID())
}

func idempotencyHeaders(_ key: UUID) -> [String: String] {
    ["Idempotency-Key": key.uuidString]
}
