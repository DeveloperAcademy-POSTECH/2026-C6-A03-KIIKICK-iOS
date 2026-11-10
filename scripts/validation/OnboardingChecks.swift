import Foundation
import SwiftUI

// iOS 저장소를 대체한다. 실제 Endpoint/DTO/완료 모델/라우터를 아래에서 검증한다.
enum APIConfig { static let baseURL = URL(string: "https://example.invalid")! }
enum NetworkService { static var provider: any Provider { fatalError("테스트는 Provider를 주입해야 합니다") } }
struct WorkoutRecord: Hashable {}
enum UserSession {
    static var userId: UUID?
    static var token: String?
    static var nickname: String?
    static var requiresOnboarding = true
    static func save(session: SessionResponse) {
        userId = session.user.id
        token = session.accessToken
        update(profile: session.user)
    }
    static func update(profile: AuthUserResponse) {
        nickname = profile.nickname
        requiresOnboarding = profile.onboardingStatus == .required
    }
    static func saveAvatar(url: String, for ownerID: UUID, imageData: Data?) {}
    static func clear() { userId = nil; token = nil; nickname = nil; requiresOnboarding = true }
}

final class ScriptedProvider: Provider {
    enum Reply { case signup, required, completed, avatar, failure, signupConflict, wait }
    var replies: [Reply]
    var requests: [URLRequest] = []
    let userID = UUID()
    init(_ replies: [Reply]) { self.replies = replies }
    func profile(_ status: OnboardingStatus) -> AuthUserResponse {
        AuthUserResponse(id: userID, nickname: status == .completed ? "준킥" : nil,
                         avatarUrl: nil, onboardingStatus: status, comparisonConsent: false, createdAt: .now)
    }
    func request<R: Decodable, E: RequestResponsable>(with endpoint: E) async throws -> R where E.Response == R {
        requests.append(try endpoint.getUrlRequest())
        precondition(!replies.isEmpty, "예상하지 못한 요청: \(endpoint.path)")
        let reply = replies.removeFirst()
        await Task.yield()
        let meta = ResponseMeta(requestId: "check", serverTime: .now)
        let value: Any
        switch reply {
        case .signup:
            value = Envelope(data: SessionResponse(sessionId: UUID(), accessToken: "test", refreshToken: "test",
                                                   expiresAt: .distantFuture, user: profile(.required)), meta: meta)
        case .required: value = Envelope(data: profile(.required), meta: meta)
        case .completed: value = Envelope(data: profile(.completed), meta: meta)
        case .avatar: value = Envelope(data: AvatarResponse(avatarUrl: "https://example.invalid/avatar.jpg"), meta: meta)
        case .signupConflict:
            throw NetworkError.invalidHttpStatusCode(409, message: "회원가입을 완료할 수 없습니다.")
        case .failure: throw NetworkError.invalidHttpStatusCode(503, message: "다시 시도")
        case .wait:
            try await Task.sleep(for: .seconds(30))
            throw CancellationError()
        }
        guard let result = value as? R else { fatalError("잘못된 응답 타입: \(R.self)") }
        return result
    }
    func requestWithoutResponse<E: RequestResponsable>(with endpoint: E) async throws where E.Response == Void {
        fatalError("예상하지 못한 요청")
    }
    func request(_ url: URL) async throws -> Data { fatalError("예상하지 못한 요청") }
    var paths: [String] { requests.compactMap { $0.url?.path } }
}

@main struct OnboardingChecks {
    @MainActor static func main() async throws {
        let signup = "/api/v1/auth/signup"
        let profile = "/api/v1/users/me"
        let onboarding = "/api/v1/users/me/onboarding"
        let avatar = "/api/v1/users/me/avatar"

        UserSession.clear()
        let success = ScriptedProvider([.signup, .required, .completed])
        let model = SignUpCompletionModel(provider: success)
        await model.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(success.paths == [signup, profile, onboarding])
        precondition(model.isWelcoming && !model.isSubmitting && !UserSession.requiresOnboarding)
        let request = success.requests[2]
        precondition(request.httpMethod == "PUT")
        precondition(request.value(forHTTPHeaderField: "Authorization") == "Bearer test")
        precondition(UUID(uuidString: request.value(forHTTPHeaderField: "Idempotency-Key") ?? "") != nil)
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        precondition(body["nickname"] as? String == "준킥")
        precondition((body["consents"] as? [Any])?.isEmpty == true)
        await model.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(success.requests.count == 3)

        UserSession.clear()
        let conflict = ScriptedProvider([.signupConflict])
        let conflictModel = SignUpCompletionModel(provider: conflict)
        conflictModel.selectedPhotoData = Data([1, 2, 3])
        await conflictModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(conflict.paths == [signup])
        precondition(!conflictModel.isWelcoming && !conflictModel.hasCreatedAccount)
        precondition(conflictModel.errorMessage?.contains("로그인") == true)

        UserSession.clear()
        let retry = ScriptedProvider([.signup, .failure, .avatar, .required, .failure, .required, .completed])
        let retryModel = SignUpCompletionModel(provider: retry)
        retryModel.selectedPhotoData = Data([1, 2, 3])
        await retryModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(!retryModel.isWelcoming && retryModel.errorMessage != nil)
        precondition(retryModel.selectedPhotoData != nil)
        await retryModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(!retryModel.isWelcoming && retryModel.selectedPhotoData == nil)
        await retryModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(retryModel.isWelcoming)
        precondition(retry.paths == [signup, avatar, avatar, profile, onboarding, profile, onboarding])
        let puts = retry.requests.filter { $0.httpMethod == "PUT" }
        precondition(puts[0].httpBody == puts[1].httpBody)
        precondition(puts[0].value(forHTTPHeaderField: "Idempotency-Key") == puts[1].value(forHTTPHeaderField: "Idempotency-Key"))
        precondition(retry.requests[2].value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data") == true)

        UserSession.clear()
        let lostReply = ScriptedProvider([.signup, .required, .failure, .completed])
        let lostModel = SignUpCompletionModel(provider: lostReply)
        await lostModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        await lostModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        precondition(lostModel.isWelcoming && lostReply.paths == [signup, profile, onboarding, profile])

        UserSession.clear()
        let resume = ScriptedProvider([.required, .completed])
        UserSession.save(session: SessionResponse(sessionId: UUID(), accessToken: "test", refreshToken: "test",
                                                 expiresAt: .distantFuture, user: resume.profile(.required)))
        let router = AppRouter()
        router.didLogIn()
        precondition(router.flow == .onboarding)
        router.finishSplash(isLoggedIn: true)
        precondition(router.flow == .onboarding)
        let resumeModel = SignUpCompletionModel(provider: resume)
        await resumeModel.complete(registrationToken: nil, password: nil, nickname: "준킥")
        precondition(resume.paths == [profile, onboarding] && resumeModel.isWelcoming)
        router.selection = .myPage
        router.didCompleteOnboarding()
        precondition(router.flow == .main && router.selection == .home)

        UserSession.clear()
        let concurrent = ScriptedProvider([.signup, .required, .completed])
        let concurrentModel = SignUpCompletionModel(provider: concurrent)
        let first = Task { await concurrentModel.complete(registrationToken: "registration", password: "password", nickname: "준킥") }
        await Task.yield()
        await concurrentModel.complete(registrationToken: "registration", password: "password", nickname: "준킥")
        await first.value
        precondition(concurrent.paths == [signup, profile, onboarding])

        UserSession.clear()
        let cancelled = ScriptedProvider([.signup, .wait])
        let cancelledModel = SignUpCompletionModel(provider: cancelled)
        let pending = Task { await cancelledModel.complete(registrationToken: "registration", password: "password", nickname: "준킥") }
        while cancelled.requests.count < 2 { await Task.yield() }
        pending.cancel()
        await pending.value
        precondition(!cancelledModel.isWelcoming && !cancelledModel.isSubmitting && cancelledModel.errorMessage == nil)
        print("온보딩 검증 통과: 요청 계약, 선택 사진, 부분 실패 재시도, 응답 유실, 재진입, 중복 탭, 취소, 홈 라우팅")
    }
}
