//
//  MockProvider.swift
//  KIIKICK
//
//  서버 없이 ViewModel/화면을 테스트·프리뷰할 때 쓰는 Provider.
//  endpoint.path를 key로 고정 응답(Data)을 등록해두면, 실제 요청 대신 그 응답을 돌려준다.
//

import Foundation

enum MockProviderError: LocalizedError {
    case stubNotFound(key: String)

    var errorDescription: String? {
        switch self {
        case .stubNotFound(let key): return "Mock stub이 없습니다: \(key)"
        }
    }
}

final class MockProvider: Provider {
    /// key: endpoint.path (URL 요청은 url.absoluteString)
    var stubs: [String: Data]
    /// 설정하면 모든 요청이 이 에러로 실패
    var forcedError: Error?
    /// 실제 네트워크처럼 비동기 지연을 흉내낼 때 쓴다 (초 단위).
    var delay: TimeInterval
    /// 테스트 검증용 호출 기록
    private(set) var requestedPaths: [String] = []
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    init(stubs: [String: Data] = [:], forcedError: Error? = nil, delay: TimeInterval = 0) {
        self.stubs = stubs
        self.forcedError = forcedError
        self.delay = delay
    }
    
    func request<R: Decodable, E: RequestResponsable>(with endpoint: E) async throws -> R where E.Response == R {
        requestedPaths.append(endpoint.path)
        try await wait()
        if let forcedError { throw forcedError }
        guard let data = stubs[endpoint.path] else {
            throw MockProviderError.stubNotFound(key: endpoint.path)
        }
        return try Self.decoder.decode(R.self, from: data)
    }
    
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E) async throws where E.Response == Void {
        requestedPaths.append(endpoint.path)
        try await wait()
        if let forcedError { throw forcedError }
    }
    
    func request(_ url: URL) async throws -> Data {
        requestedPaths.append(url.absoluteString)
        try await wait()
        if let forcedError { throw forcedError }
        guard let data = stubs[url.absoluteString] else {
            throw MockProviderError.stubNotFound(key: url.absoluteString)
        }
        return data
    }
    
    private func wait() async throws {
        guard delay > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
