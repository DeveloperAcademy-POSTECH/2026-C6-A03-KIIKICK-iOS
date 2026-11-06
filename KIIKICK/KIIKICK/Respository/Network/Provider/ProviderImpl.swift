//
//  ProviderImpl.swift
//  KIIKICK
//
//  `Provider`의 실제(URLSession 기반) 구현.
//

import Foundation

final class ProviderImpl: Provider {
    private let session: URLSessionable
    
    init(session: URLSessionable = URLSession.shared) {
        self.session = session
    }
    
    func request<R: Decodable, E: RequestResponsable>(with endpoint: E) async throws -> R where E.Response == R {
        let data = try await execute(endpoint)
        return try decode(data: data)
    }
    
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E) async throws where E.Response == Void {
        _ = try await execute(endpoint)
    }
    
    func request(_ url: URL) async throws -> Data {
        let (data, response) = try await transport { try await self.session.data(from: url) }
        try validate(response, data: data)
        return data
    }
    
    private func execute<E: Requestable>(_ endpoint: E) async throws -> Data {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.getUrlRequest()
        } catch {
            throw NetworkError.urlRequest(error)
        }
        
        let (data, response) = try await transport { try await self.session.data(for: urlRequest) }
        try validate(response, data: data)
        return data
    }
    
    private func transport(_ work: () async throws -> (Data, URLResponse)) async throws -> (Data, URLResponse) {
        do {
            return try await work()
        } catch {
            throw NetworkError.urlRequest(error)
        }
    }
    
    private func validate(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerErrorBody.self, from: data))?.error.message
                ?? String(data: data, encoding: .utf8)
            throw NetworkError.invalidHttpStatusCode(httpResponse.statusCode, message: message)
        }
    }
    
    private func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodeError
        }
    }
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            
            let parts = raw.split(separator: ".", maxSplits: 1)
            let wholePart = String(parts[0])
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            guard let baseDate = formatter.date(from: wholePart) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "날짜 형식을 해석할 수 없습니다: \(raw)")
            }
            
            guard parts.count == 2, let fraction = Double("0.\(parts[1])") else {
                return baseDate
            }
            return baseDate.addingTimeInterval(fraction)
        }
        return decoder
    }()
}

/// 공통 오류 응답은 {"error": {"message": ...}, "meta": {...}} 형태로 message가
/// error 아래 중첩돼 있다(common.md). 과거엔 message가 최상위에 있다고 잘못 가정해서
/// 디코딩이 항상 실패하고 원문 JSON이 그대로 에러 메시지로 쓰였다.
private struct ServerErrorBody: Decodable {
    struct ErrorDetail: Decodable { let message: String }
    let error: ErrorDetail
}
