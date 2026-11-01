//
//  APIClient.swift
//  KIIKICK
//
//  얇은 공용 HTTP 클라이언트. BaseURL은 APIConfig(xcconfig)에서 가져온다.
//

import Foundation

enum APIError: Error {
    case invalidResponse
    case serverError(statusCode: Int, message: String?)
}

private struct ServerErrorBody: Decodable {
    let message: String
}

extension JSONDecoder {
    /// 서버가 내려주는 날짜 문자열은 타임존 표기가 없는 UTC(예: "2026-10-30T06:22:51.887409")라,
    /// 기본 .iso8601 전략으로는 못 읽는다. 초 단위까지 파싱한 뒤 소수점 이하를 별도로 더한다.
    static let kiikickAPI: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let parts = raw.split(separator: ".", maxSplits: 1)
            let wholePart = String(parts[0])

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "UTC")
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

enum APIClient {
    static func send<Response: Decodable>(path: String, method: String, body: (any Encodable)? = nil) async throws -> Response {
        let (data, response) = try await execute(path: path, method: method, body: body)
        try validate(response, data: data)
        return try JSONDecoder.kiikickAPI.decode(Response.self, from: data)
    }

    static func sendNoContent(path: String, method: String, body: (any Encodable)? = nil) async throws {
        let (data, response) = try await execute(path: path, method: method, body: body)
        try validate(response, data: data)
    }

    private static func execute(path: String, method: String, body: (any Encodable)?) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: APIConfig.baseURL.appending(path: path))
        request.httpMethod = method

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        return try await URLSession.shared.data(for: request)
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerErrorBody.self, from: data))?.message
                ?? String(data: data, encoding: .utf8)
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
