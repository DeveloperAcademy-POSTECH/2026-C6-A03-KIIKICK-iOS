//
//  Field.swift
//  KIIKICK
//

import Foundation
import SwiftData

struct FieldCorner: Codable {
    let latitude: Double
    let longitude: Double
}

@Model
final class Field {
    var name: String
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
        rawCornerC: FieldCorner? = nil, rawCornerD: FieldCorner? = nil
    ) {
        self.name = name
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
