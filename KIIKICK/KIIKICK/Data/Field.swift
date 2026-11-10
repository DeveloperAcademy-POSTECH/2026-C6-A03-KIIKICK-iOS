//
//  Field.swift
//  KIIKICK
//

import Foundation
import SwiftData

struct FieldCorner: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

enum FieldNameRules {
    static let maxLength = 18

    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validationMessage(for name: String) -> String? {
        let normalizedName = normalized(name)
        if name.count > maxLength {
            return "경기장 이름은 최대 \(maxLength)자까지 입력할 수 있어요"
        }
        if !name.isEmpty && normalizedName.isEmpty {
            return "공백만으로는 이름을 설정할 수 없어요"
        }
        if name.contains(where: \.isKiikickFieldNameDisallowed) {
            return "사용할 수 없는 문자가 포함되어 있어요"
        }
        return nil
    }

    static func canSave(_ name: String) -> Bool {
        !normalized(name).isEmpty && validationMessage(for: name) == nil
    }
}

@Model
final class Field {
    var name: String
    /// 서버 저장 경기장의 식별자. nil이면 API 연동 전에 생성된 로컬 경기장이다.
    var serverID: UUID?
    var address: String?
    var serverUpdatedAt: Date?
    /// 경기 기록의 Field 참조를 보존하면서 내 경기장 목록에서만 제외한다.
    var isArchived: Bool = false
    /// 기존 로컬 경기장을 서버로 이전할 때 재시도에도 같은 멱등 키를 사용한다.
    var createIdempotencyKey: UUID?
    /// 직사각형으로 보정된 꼭짓점 — 히트맵 등 실제 연산은 전부 이 값을 쓴다.
    var cornerA: FieldCorner
    var cornerB: FieldCorner
    var cornerC: FieldCorner
    var cornerD: FieldCorner
    /// 사용자가 실제로 찍은 원본 핀. 재보정·디버깅 대비로 같이 보관한다(연산에는 쓰지 않음).
    var rawCornerA: FieldCorner?
    var rawCornerB: FieldCorner?
    var rawCornerC: FieldCorner?
    var rawCornerD: FieldCorner?

    init(
        name: String,
        cornerA: FieldCorner, cornerB: FieldCorner, cornerC: FieldCorner, cornerD: FieldCorner,
        rawCornerA: FieldCorner? = nil, rawCornerB: FieldCorner? = nil,
        rawCornerC: FieldCorner? = nil, rawCornerD: FieldCorner? = nil,
        serverID: UUID? = nil, address: String? = nil, serverUpdatedAt: Date? = nil,
        isArchived: Bool = false, createIdempotencyKey: UUID? = nil
    ) {
        self.name = name
        self.serverID = serverID
        self.address = address
        self.serverUpdatedAt = serverUpdatedAt
        self.isArchived = isArchived
        self.createIdempotencyKey = createIdempotencyKey
        self.cornerA = cornerA
        self.cornerB = cornerB
        self.cornerC = cornerC
        self.cornerD = cornerD
        self.rawCornerA = rawCornerA
        self.rawCornerB = rawCornerB
        self.rawCornerC = rawCornerC
        self.rawCornerD = rawCornerD
    }
}

extension Character {
    /// 이모지만 막는다. 숫자/#처럼 일반 글자로 표시되는 emoji 스칼라는 허용한다.
    var isKiikickFieldNameDisallowed: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 0x238C)
    }
}
