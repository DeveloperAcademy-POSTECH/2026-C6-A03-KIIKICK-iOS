//
//  APIConfig.swift
//  KIIKICK
//

import Foundation

enum APIConfig {
    static var baseURL: URL {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "BaseURL") as? String,
              let url = URL(string: string) else {
            fatalError("BaseURL이 설정되어 있지 않습니다. KIIKICK/Config.xcconfig의 BASE_URL 값을 확인하세요.")
        }
        return url
    }
}
