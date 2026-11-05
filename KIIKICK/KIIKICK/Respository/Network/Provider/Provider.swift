//
//  Provider.swift
//  iOS Network Layer
//
//  Created by Seungjun Lee on 11/3/26.
//

import Foundation

protocol Provider {
    func request<R: Decodable, E: RequestResponsable>(with endpoint: E) async throws -> R where E.Response == R
    
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E) async throws where E.Response == Void
    
    func request(_ url: URL) async throws -> Data
}
