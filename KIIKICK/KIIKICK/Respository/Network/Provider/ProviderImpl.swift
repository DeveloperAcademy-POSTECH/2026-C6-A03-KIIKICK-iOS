//
//  ProviderImpl.swift
//  KIIKICK
//
//  `Provider`의 실제(URLSession 기반) 구현.
//

import Foundation
import OSLog

final class ProviderImpl: Provider {
    private let session: URLSessionable
    private static let logger = Logger(subsystem: "KIIKICK", category: "Network")
    
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
        let request = URLRequest(url: url)
        let (data, response) = try await transport(request: request) { try await self.session.data(from: url) }
        try validate(response, data: data, request: request)
        return data
    }
    
    private func execute<E: Requestable>(_ endpoint: E) async throws -> Data {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.getUrlRequest()
        } catch {
            throw NetworkError.urlRequest(error)
        }
        
        let (data, response) = try await transport(request: urlRequest) { try await self.session.data(for: urlRequest) }
        try validate(response, data: data, request: urlRequest)
        return data
    }
    
    private func transport(request: URLRequest, _ work: () async throws -> (Data, URLResponse)) async throws -> (Data, URLResponse) {
        #if DEBUG
        print("[API] → \(request.httpMethod ?? "GET") \(request.url?.path ?? "") START")
        #endif
        do {
            return try await work()
        } catch {
            #if DEBUG
            let failure = error as NSError
            print("[API] ← \(request.httpMethod ?? "GET") \(request.url?.path ?? "") transportError=\(failure.domain):\(failure.code)")
            #endif
            throw NetworkError.urlRequest(error)
        }
    }
    
    private func validate(_ response: URLResponse, data: Data, request: URLRequest) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknownError
        }
        #if DEBUG
        logHTTPResponse(httpResponse, data: data, request: request)
        #endif
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerErrorBody.self, from: data))?.error.fullMessage
                ?? String(data: data, encoding: .utf8)
            throw NetworkError.invalidHttpStatusCode(httpResponse.statusCode, message: message)
        }
    }
    
    #if DEBUG
    private func logHTTPResponse(_ response: HTTPURLResponse, data: Data, request: URLRequest) {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        if (200...299).contains(response.statusCode) {
            print("[API] ← \(method) \(path) HTTP \(response.statusCode)")
        } else {
            // details나 메시지 형식이 달라도 진단 코드는 읽는다. 본문·쿼리·헤더는 기록하지 않는다.
            let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let code = (body?["error"] as? [String: Any])?["code"] as? String ?? "UNKNOWN"
            let requestID = (body?["meta"] as? [String: Any])?["requestId"] as? String ?? "UNKNOWN"
            print("[API] ← \(method) \(path) HTTP \(response.statusCode) code=\(code) requestId=\(requestID)")
        }
    }
    #endif

    private func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            let path: [CodingKey]
            switch error {
            case .keyNotFound(let key, let context):
                path = context.codingPath + [key]
            case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
                path = context.codingPath
            @unknown default:
                path = []
            }
            // 토큰·이메일·인증번호가 담긴 본문 대신 실패한 필드 경로만 기록한다.
            let field = path.map(\.stringValue).joined(separator: ".")
            #if DEBUG
            print("[API] DECODE_ERROR type=\(String(reflecting: T.self)) field=\(field)")
            #endif
            Self.logger.error("API 응답 디코딩 실패: \(String(reflecting: T.self), privacy: .public), 필드: \(field, privacy: .public)")
            throw NetworkError.decodeError
        } catch {
            throw NetworkError.decodeError
        }
    }
    
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            
            // 인증 API는 +09:00/Z와 선택적인 소수초가 포함된 시각을 반환한다.
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: raw) {
                return date
            }
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: raw) {
                return date
            }

            // 기존 API의 시간대 없는 날짜는 기존 계약대로 서울 시각으로 해석한다.
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

            let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            guard let wholePart = parts.first,
                  let baseDate = formatter.date(from: String(wholePart)) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "날짜 형식을 해석할 수 없습니다: \(raw)")
            }
            guard parts.count == 2 else {
                return baseDate
            }
            guard !parts[1].isEmpty, parts[1].allSatisfy({ $0.isASCII && $0.isNumber }),
                  let fraction = Double("0.\(parts[1])") else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "날짜 형식을 해석할 수 없습니다: \(raw)")
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
    struct ErrorDetail: Decodable {
        let message: String
        /// 필드별 검증 실패 상세(예: 422). 값이 평범한 문자열 맵이 아니면(중첩 객체 등)
        /// 디코딩이 그냥 nil이 되고 message만 쓰인다 — 그래도 괜찮다, 완전히 실패하면
        /// ProviderImpl.validate가 원본 JSON 문자열로 폴백한다.
        let details: [String: String]?

        var fullMessage: String {
            guard let details, !details.isEmpty else { return message }
            let detailText = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            return "\(message) (\(detailText))"
        }
    }
    let error: ErrorDetail
}
