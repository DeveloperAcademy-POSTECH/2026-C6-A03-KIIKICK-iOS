import Foundation
import Observation

@MainActor @Observable
final class SignUpCompletionModel {
    private(set) var isSubmitting = false
    private(set) var isWelcoming = false
    private(set) var hasCreatedAccount = false
    var errorMessage: String?
    var selectedPhotoData: Data?

    private let provider: any Provider
    private let idempotencyKey = UUID()
    private var ownerID: UUID?

    init(provider: (any Provider)? = nil) {
        self.provider = provider ?? NetworkService.provider
    }

    func complete(registrationToken: String?, password: String?, nickname: String) async {
        #if DEBUG
        print("[API] ONBOARDING_SUBMIT photoSelected=\(selectedPhotoData != nil) isSubmitting=\(isSubmitting) isWelcoming=\(isWelcoming)")
        #endif
        guard !isSubmitting, !isWelcoming else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            if ownerID == nil {
                if let registrationToken, let password {
                    let session = try await provider.request(
                        with: AuthEndpoints.signup(registrationToken: registrationToken, password: password)
                    )
                    UserSession.save(session: session.data)
                    ownerID = session.data.user.id
                } else {
                    ownerID = UserSession.userId
                }
                hasCreatedAccount = ownerID != nil
            }
            guard let ownerID, UserSession.userId == ownerID, UserSession.token != nil else {
                errorMessage = "로그인이 필요해요. 다시 로그인해 주세요"
                return
            }
            try Task.checkCancellation()

            if let selectedPhotoData {
                let avatar = try await provider.request(with: AvatarEndpoints.upload(jpegData: selectedPhotoData))
                guard UserSession.userId == ownerID else { return }
                UserSession.saveAvatar(url: avatar.data.avatarUrl, for: ownerID, imageData: selectedPhotoData)
                self.selectedPhotoData = nil
            }
            try Task.checkCancellation()

            // 재진입 또는 응답 유실 후에도 이미 완료된 계정에 새 PUT을 보내지 않는다.
            let current = try await provider.request(with: AuthEndpoints.profile())
            guard UserSession.userId == ownerID else { return }
            if current.data.onboardingStatus == .completed {
                UserSession.update(profile: current.data)
            } else {
                let profile = try await provider.request(
                    with: AuthEndpoints.completeOnboarding(nickname: nickname, idempotencyKey: idempotencyKey)
                )
                guard UserSession.userId == ownerID else { return }
                UserSession.update(profile: profile.data)
            }
            try Task.checkCancellation()
            guard !UserSession.requiresOnboarding else {
                errorMessage = "가입을 완료하지 못했어요. 다시 시도해 주세요"
                return
            }
            isWelcoming = true
        } catch {
            guard !Task.isCancelled else { return }
            if case let NetworkError.invalidHttpStatusCode(status, message) = error {
                if !hasCreatedAccount, status == 409 {
                    // signup의 409는 가입 중복·충돌이다. 사진 업로드나 온보딩 실패와 구분한다.
                    errorMessage = "이미 가입된 계정이거나 가입 요청이 충돌했어요. 시작 화면에서 로그인해 주세요"
                } else {
                    errorMessage = message ?? "가입을 완료하지 못했어요. 다시 시도해 주세요"
                }
            } else {
                errorMessage = "가입을 완료하지 못했어요. 다시 시도해 주세요"
            }
        }
    }
}
