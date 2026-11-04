//
//  Responsable.swift
//  iOS Network Layer
//
//  Created by Seungjun Lee on 11/3/26.
//

import Foundation

protocol Responsable {
    associatedtype Response
}

protocol RequestResponsable: Requestable, Responsable { }
