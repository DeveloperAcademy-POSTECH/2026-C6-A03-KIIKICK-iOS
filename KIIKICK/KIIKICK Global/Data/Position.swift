//
//  Position.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

enum Position: String, CaseIterable {
    case lw, st, rw, lm, cm, rm, lb, cb, rb, gk
    
    var uppercased: String {
        return self.rawValue.uppercased()
    }
}
