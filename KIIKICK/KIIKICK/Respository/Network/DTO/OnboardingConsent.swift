struct OnboardingConsent: Encodable {
    let purpose: String
    let policyVersion: String
    let granted: Bool
}
