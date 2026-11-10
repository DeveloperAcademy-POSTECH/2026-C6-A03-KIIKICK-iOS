//
//  VenueDTO.swift
//  KIIKICK
//

import Foundation

struct VenueResponse: Decodable {
    let id: UUID
    let name: String
    let address: String?
    let cornerA: FieldCorner?
    let cornerB: FieldCorner?
    let cornerC: FieldCorner?
    let cornerD: FieldCorner?
    let rawCornerA: FieldCorner?
    let rawCornerB: FieldCorner?
    let rawCornerC: FieldCorner?
    let rawCornerD: FieldCorner?
    let createdAt: Date
    let updatedAt: Date

    var correctedCorners: [FieldCorner]? {
        guard let cornerA, let cornerB, let cornerC, let cornerD else { return nil }
        return [cornerA, cornerB, cornerC, cornerD]
    }
}

struct VenueCreateRequest: Encodable {
    let name: String
    let address: String?
    let cornerA: FieldCorner
    let cornerB: FieldCorner
    let cornerC: FieldCorner
    let cornerD: FieldCorner
    let rawCornerA: FieldCorner?
    let rawCornerB: FieldCorner?
    let rawCornerC: FieldCorner?
    let rawCornerD: FieldCorner?

    init(field: Field, name: String? = nil) {
        self.name = name ?? field.name
        address = field.address
        cornerA = field.cornerA
        cornerB = field.cornerB
        cornerC = field.cornerC
        cornerD = field.cornerD
        rawCornerA = field.rawCornerA
        rawCornerB = field.rawCornerB
        rawCornerC = field.rawCornerC
        rawCornerD = field.rawCornerD
    }

    init(name: String, corrected: [FieldCorner], raw: [FieldCorner]) {
        precondition(corrected.count == 4 && raw.count == 4)
        self.name = name
        address = nil
        cornerA = corrected[0]
        cornerB = corrected[1]
        cornerC = corrected[2]
        cornerD = corrected[3]
        rawCornerA = raw[0]
        rawCornerB = raw[1]
        rawCornerC = raw[2]
        rawCornerD = raw[3]
    }
}

