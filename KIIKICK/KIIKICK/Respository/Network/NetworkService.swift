//
//  NetworkService.swift
//  KIIKICK
//
//  앱 전체가 공유하는 단일 Provider. 호출부는 `NetworkService.provider.request(with: ...)`로
//  Endpoint를 직접 넘긴다. 테스트/프리뷰에서는 `NetworkService.provider = MockProvider(...)`로 교체한다.
//

import Foundation

enum NetworkService {
    static var provider: Provider = ProviderImpl()
}
