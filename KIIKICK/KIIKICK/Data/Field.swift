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
    var cornerA: FieldCorner
    var cornerB: FieldCorner
    var cornerC: FieldCorner
    var cornerD: FieldCorner
    
    init(name: String, cornerA: FieldCorner, cornerB: FieldCorner, cornerC: FieldCorner, cornerD: FieldCorner) {
        self.name = name
        self.cornerA = cornerA
        self.cornerB = cornerB
        self.cornerC = cornerC
        self.cornerD = cornerD
    }
}
