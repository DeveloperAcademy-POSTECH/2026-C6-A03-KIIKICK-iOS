import Foundation

struct OnboardingRequest: Encodable {
    let nickname: String
    // 동의 선택 UI가 없으므로 미제출한다. OS 권한을 서버 동의로 간주하지 않는다.
    let consents: [OnboardingConsent] = []
}
