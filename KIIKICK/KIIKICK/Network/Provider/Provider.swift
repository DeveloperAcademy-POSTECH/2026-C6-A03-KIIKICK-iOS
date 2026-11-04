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

final class ProviderImple: Provider {
    
    let session: URLSessionable
    init(session:  URLSessionable = URLSession.shared) {
        self.session = session
    }
    
    func request<R, E>(with endpoint: E, completion: @escaping (Result<R, any Error>) -> Void) where R : Decodable, R == E.Response, E : RequestResponsable {
        do {
            let urlRequest = try endpoint.getUrlRequest()
            
            session.dataTask(with: urlRequest) { [weak self] data, response, error in
                self?.checkError(with: data, response, error) { result in
                    guard let `self` = self else { return }
                    
                    switch result {
                    case .success(let data):
                        completion(`self`.decode(data: data))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }.resume()
            
        } catch {
            completion(.failure(NetworkError.urlRequest(error)))
        }
    }
    
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let urlRequest = try endpoint.getUrlRequest()
            
            session.dataTask(with: urlRequest) { [weak self] data, response, error in
                self?.checkError(with: data, response, error) { result in
                    guard let `self` = self else { return }
                    
                    switch result {
                    case .success(_):
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }.resume()
            
        } catch {
            completion(.failure(NetworkError.urlRequest(error)))
        }
    }
    
    func request(_ url: URL, completion: @escaping (Result<Data, any Error>) -> ()) {
        session.dataTask(with: url) { [weak self] data, response, error in
            self?.checkError(with: data, response, error, completion: { result in
                completion(result)
            })
        }.resume()
    }
    
    
    // Private
    private func checkError(with data: Data?, _ response: URLResponse?, _ error: Error?, completion: @escaping (Result<Data, Error>) -> ()) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let response = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.unknownError))
            return
        }
        
        guard (200...299).contains(response.statusCode) else {
            completion(.failure(NetworkError.invalidHttpStatusCode(response.statusCode)))
            return
        }
        
        guard let data = data else {
            completion(.failure(NetworkError.emptyData))
            return
        }
        
        completion(.success((data)))
    }
    
    private func decode<T: Decodable>(data: Data) -> Result<T, Error> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
}

enum MockProviderError: LocalizedError {
    case stubNotFound(key: String)

    var errorDescription: String? {
        switch self {
        case .stubNotFound(let key): return "Mock stub이 없습니다: \(key)"
        }
    }
}

final class MockProductProvider: Provider {

    /// key: endpoint.path (또는 URL 요청은 url.absoluteString)
    var stubs: [String: Data]
    /// 설정하면 모든 요청이 이 에러로 실패
    var forcedError: Error?
    /// 실제 네트워크처럼 비동기 지연
    var delay: TimeInterval
    /// 테스트 검증용 호출 기록
    private(set) var requestedPaths: [String] = []

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(stubs: [String: Data] = MockProductProvider.defaultStubs,
         forcedError: Error? = nil,
         delay: TimeInterval = 0) {
        self.stubs = stubs
        self.forcedError = forcedError
        self.delay = delay
    }

    func request<R: Decodable, E: RequestResponsable>(with endpoint: E, completion: @escaping (Result<R, Error>) -> Void) where E.Response == R {
        requestedPaths.append(endpoint.path)

        let result = Result<R, Error> {
            if let forcedError { throw forcedError }
            guard let data = stubs[endpoint.path] else {
                throw MockProviderError.stubNotFound(key: endpoint.path)
            }
            return try Self.decoder.decode(R.self, from: data)
        }
        deliver(result, to: completion)
    }

    /// data를 얻는 request
    func request(_ url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
        requestedPaths.append(url.absoluteString)

        let result = Result<Data, Error> {
            if let forcedError { throw forcedError }
            guard let data = stubs[url.absoluteString] else {
                throw MockProviderError.stubNotFound(key: url.absoluteString)
            }
            return data
        }
        deliver(result, to: completion)
    }

    /// 응답이 필요 없는 request
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E, completion: @escaping (Result<Void, Error>) -> Void) where E.Response == Void {
        requestedPaths.append(endpoint.path)

        let result: Result<Void, Error> = forcedError.map { .failure($0) } ?? .success(())
        deliver(result, to: completion)
    }

    // MARK: - Helpers

    private func deliver<T>(_ result: Result<T, Error>, to completion: @escaping (Result<T, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(result)
        }
    }
}

// MARK: - Default Stubs

extension MockProductProvider {
    static let defaultStubs: [String: Data] = [
        "products": Data("""
        {
          "products": [
            { "id": 1, "title": "Essence Mascara Lash Princess", "price": 9.99 },
            { "id": 2, "title": "Eyeshadow Palette with Mirror", "price": 19.99 },
            { "id": 3, "title": "Powder Canister", "price": 14.99 }
          ]
        }
        """.utf8)
    ]
}
