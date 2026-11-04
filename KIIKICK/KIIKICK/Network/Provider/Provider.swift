//
//  Provider.swift
//  iOS Network Layer
//
//  Created by Seungjun Lee on 11/3/26.
//

import Foundation
 
/// Provider 정의
///
/// requset 2 종류
/// Endcodable한 Request  모델을 통해서 Decodable한 Response를 받는 request
/// 단순히 URL을 request로 주어 Data를 얻는 request : 이미지 url을 넣고 이미지 Data를 얻어오는 경우

protocol Provider {
    func request<R: Decodable, E: RequestResponsable>(with endpoint: E, completion: @escaping (Result<R, Error>) -> Void) where E.Response == R
    
    /// data를 얻는 request
    func request(_ url: URL, completion: @escaping (Result<Data, Error>) -> ())
    
    /// 응답이 필요 없는 request
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E, completion: @escaping (Result<Void, Error>) -> Void) where E.Response == Void
}
