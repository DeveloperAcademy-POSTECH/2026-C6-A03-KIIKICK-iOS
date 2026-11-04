//
//  APIEndpoints.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 11/4/26.
//

import Foundation

enum APIEndpoints {
    case auth   
    case match
    
    var endPoint: Endpoint<Any> {
        switch self {
        case .auth:
            return Endpoint(baseURL: "")
        case .match:
            return Endpoint(baseURL: "")
        }
    }
}
