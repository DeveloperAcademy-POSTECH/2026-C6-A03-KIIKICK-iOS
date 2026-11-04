//
//  URLSessionable.swift
//  iOS Network Layer
//
//  Created by Seungjun Lee on 11/3/26.
//

import Foundation

protocol URLSessionable {
    func data(for: URLRequest) async throws -> (Data, URLResponse)
    
    func data(from: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionable {}
