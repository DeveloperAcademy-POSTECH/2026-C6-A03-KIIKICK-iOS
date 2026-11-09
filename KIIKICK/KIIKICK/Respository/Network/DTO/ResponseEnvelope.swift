//
//  ResponseEnvelope.swift
//  KIIKICK
//
//  백엔드 docs/api/common.md 기준 공통 응답 봉투. 성공은 {data, meta:{requestId,serverTime}},
//  목록은 {data:[...], meta:{...,pagination:{nextCursor,hasNext}}} 형태를 쓴다. 제네릭으로
//  한 번만 정의해서, 도메인별 DTO는 안에 들어갈 데이터 타입만 정의하면 된다.
//

import Foundation

struct ResponseMeta: Decodable {
    // 서버의 추적 ID는 일반 문자열이며 UUID 형식을 보장하지 않는다.
    let requestId: String
    let serverTime: Date
}

struct Pagination: Decodable {
    let nextCursor: String?
    let hasNext: Bool
}

struct PageMeta: Decodable {
    let requestId: String
    let serverTime: Date
    let pagination: Pagination
}

struct Envelope<T: Decodable>: Decodable {
    let data: T
    let meta: ResponseMeta
}

struct PageEnvelope<T: Decodable>: Decodable {
    let data: [T]
    let meta: PageMeta
}
