//
//  NetworkTestView.swift
//  KIIKICK
//
//  이슈 #35: venue를 제외한 모든 신규 도메인(알림/친구/경기·쿼터/쿼터 운동기록/경기 결과/분석)
//  엔드포인트를 실제로 호출해 응답이 오는지 눈으로 확인하는 단일 테스트 뷰. DEBUG 빌드에서만 노출된다.
//
//  공통 ID 입력값은 위쪽에 모아두고, 아래 섹션의 각 행은 "실행" 버튼으로 해당 엔드포인트를
//  즉시 호출해 성공/실패와 응답을 바로 아래에 보여준다. 입력값이 비어 있으면(예: 아직 경기를
//  만들지 않아 matchId가 없는 상태) 그 사실을 에러로 보여줄 뿐 앱이 죽지 않는다.
//

#if DEBUG
import SwiftUI

struct NetworkTestView: View {
    @State private var userIdText = UserSession.userId?.uuidString ?? ""
    @State private var targetUserIdText = ""
    @State private var requestIdText = ""
    @State private var searchQueryText = "test"

    @State private var matchIdText = ""
    @State private var quarterIdText = ""
    @State private var ifMatchText = ""
    @State private var durationSecondsText = "600"
    @State private var positionCodeText = "CM"
    @State private var goalsText = "0"
    @State private var assistsText = "0"

    @State private var hrMaxText = "190"

    @State private var metricText = "totalDistance"
    @State private var fromText = ""
    @State private var toText = ""
    @State private var previousMatchIdText = ""
    @State private var subjectUserIdText = ""

    @State private var authEmailText = ""
    @State private var authPasswordText = ""
    @State private var authVerificationIdText = ""
    @State private var authCodeText = ""
    @State private var authRegistrationTokenText = ""
    @State private var authNicknameText = ""

    var body: some View {
        List {
            inputSection
            authSection
            notificationSection
            friendSection
            matchSection
            quarterSection
            quarterWorkoutSection
            matchResultSection
            analyticsSection
        }
        .navigationTitle("API 테스트")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 공통 입력값

    private var inputSection: some View {
        Section("공통 입력값") {
            labeledField("내 userId", $userIdText)
            labeledField("상대 userId (친구/대상)", $targetUserIdText)
            labeledField("친구요청 requestId", $requestIdText)
            labeledField("검색어", $searchQueryText)
            labeledField("matchId", $matchIdText)
            labeledField("quarterId", $quarterIdText)
            labeledField("If-Match (임시)", $ifMatchText)
            labeledField("durationSeconds", $durationSecondsText)
            labeledField("positionCode", $positionCodeText)
            labeledField("goals", $goalsText)
            labeledField("assists", $assistsText)
            labeledField("hrMaxReferenceBpm", $hrMaxText)
            labeledField("metric", $metricText)
            labeledField("from (RFC3339, 선택)", $fromText)
            labeledField("to (RFC3339, 선택)", $toText)
            labeledField("previousMatchId (선택)", $previousMatchIdText)
            labeledField("subjectUserId (선택)", $subjectUserIdText)
        }
    }

    private func labeledField(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            TextField(label, text: text)
                .font(.caption)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    // MARK: - 인증 (이메일 인증 → 회원가입/로그인)

    private var authSection: some View {
        Section("인증") {
            labeledField("email", $authEmailText)
            labeledField("password", $authPasswordText)
            labeledField("인증코드(메일로 받음)", $authCodeText)
            labeledField("verificationId(자동)", $authVerificationIdText)
            labeledField("registrationToken(자동)", $authRegistrationTokenText)
            labeledField("nickname(프로필 수정용)", $authNicknameText)

            row("[AUTH] 이메일 인증 코드 발송") {
                let result = try await NetworkService.provider.request(
                    with: AuthEndpoints.requestEmailVerification(email: authEmailText)
                )
                authVerificationIdText = result.data.verificationId.uuidString
                return result
            }
            row("[AUTH] 인증 코드 확인 → registrationToken") {
                let id = try requiredUUID(authVerificationIdText, "verificationId")
                let result = try await NetworkService.provider.request(
                    with: AuthEndpoints.verifyEmailVerification(verificationId: id, code: authCodeText)
                )
                authRegistrationTokenText = result.data.registrationToken
                return result
            }
            row("[AUTH] 회원가입") {
                let result = try await NetworkService.provider.request(
                    with: AuthEndpoints.signup(registrationToken: authRegistrationTokenText, password: authPasswordText)
                )
                UserSession.save(session: result.data)
                userIdText = result.data.user.id.uuidString
                return result
            }
            row("[AUTH] 로그인") {
                let result = try await NetworkService.provider.request(
                    with: AuthEndpoints.login(email: authEmailText, password: authPasswordText)
                )
                UserSession.save(session: result.data)
                userIdText = result.data.user.id.uuidString
                return result
            }
            row("[AUTH] 세션 갱신") {
                guard let refreshToken = UserSession.refreshToken else { throw TestInputError.missing("refreshToken (로그인/가입 먼저)") }
                let result = try await NetworkService.provider.request(with: AuthEndpoints.refresh(refreshToken: refreshToken))
                UserSession.save(session: result.data)
                return result
            }
            row("[AUTH] 로그아웃") {
                try await NetworkService.provider.requestWithoutResponse(with: AuthEndpoints.logout(sessionId: UserSession.sessionId))
                return "OK"
            }
            row("[AUTH] 내 프로필 조회") {
                try await NetworkService.provider.request(with: AuthEndpoints.profile())
            }
            row("[AUTH] 내 프로필 수정") {
                try await NetworkService.provider.request(with: AuthEndpoints.updateProfile(nickname: optionalText(authNicknameText)))
            }
        }
    }

    // MARK: - 알림 (NOTI-01~05)

    private var notificationSection: some View {
        Section("알림") {
            row("[NOTI-01] 알림 목록") {
                try await NetworkService.provider.request(with: NotificationEndpoints.list())
            }
            row("[NOTI-02] 안읽은 알림 수") {
                try await NetworkService.provider.request(with: NotificationEndpoints.unreadCount())
            }
            row("[NOTI-03] 알림 읽음 처리") {
                let id = try requiredUUID(notificationIdPlaceholder, "notificationId (requestId 칸에 입력)")
                return try await NetworkService.provider.request(with: NotificationEndpoints.markRead(notificationId: id))
            }
            row("[NOTI-04] 기기 등록/갱신") {
                let id = try requiredUUID(deviceIdPlaceholder, "deviceId (quarterId 칸에 입력)")
                return try await NetworkService.provider.request(
                    with: NotificationEndpoints.updateDevice(deviceId: id, platform: .ios, pushToken: nil, pushEnabled: true)
                )
            }
            row("[NOTI-05] 기기 등록 해제") {
                let id = try requiredUUID(deviceIdPlaceholder, "deviceId (quarterId 칸에 입력)")
                try await NetworkService.provider.requestWithoutResponse(with: NotificationEndpoints.unregisterDevice(deviceId: id))
                return "OK"
            }
        }
    }

    // MARK: - 친구 (FRIEND-01~10)

    private var friendSection: some View {
        Section("친구") {
            row("[FRIEND-01] 사용자 검색") {
                try await NetworkService.provider.request(with: FriendEndpoints.searchUsers(query: searchQueryText))
            }
            row("[FRIEND-02] 공개 프로필 조회") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                return try await NetworkService.provider.request(with: FriendEndpoints.profile(userId: id))
            }
            row("[FRIEND-03] 내 친구 목록") {
                try await NetworkService.provider.request(with: FriendEndpoints.listFriends())
            }
            row("[FRIEND-04] 받은 친구 요청 목록") {
                try await NetworkService.provider.request(with: FriendEndpoints.listFriendRequests(direction: .received))
            }
            row("[FRIEND-04] 보낸 친구 요청 목록") {
                try await NetworkService.provider.request(with: FriendEndpoints.listFriendRequests(direction: .sent))
            }
            row("[FRIEND-05] 친구 요청 보내기") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                return try await NetworkService.provider.request(with: FriendEndpoints.sendFriendRequest(targetUserId: id))
            }
            row("[FRIEND-06] 친구 요청 수락") {
                let id = try requiredUUID(requestIdText, "requestId")
                return try await NetworkService.provider.request(with: FriendEndpoints.acceptFriendRequest(requestId: id))
            }
            row("[FRIEND-07] 친구 요청 취소·거절") {
                let id = try requiredUUID(requestIdText, "requestId")
                try await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.cancelOrRejectFriendRequest(requestId: id))
                return "OK"
            }
            row("[FRIEND-08] 친구 삭제") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                try await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.removeFriend(userId: id))
                return "OK"
            }
            row("[FRIEND-09] 사용자 차단") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                try await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.blockUser(userId: id))
                return "OK"
            }
            row("[FRIEND-10] 차단 해제") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                try await NetworkService.provider.requestWithoutResponse(with: FriendEndpoints.unblockUser(userId: id))
                return "OK"
            }
        }
    }

    // MARK: - 경기 (SET-06~11, GAME-01,12)

    private var matchSection: some View {
        Section("경기") {
            row("[SET-06] 내 경기 목록") {
                try await NetworkService.provider.request(with: MatchEndpoints.list())
            }
            row("[SET-07] 경기 생성") {
                try await NetworkService.provider.request(with: MatchEndpoints.create(title: "테스트 경기"))
            }
            row("[SET-08] 경기 상세") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchEndpoints.detail(matchId: id))
            }
            row("[SET-09] 경기 설정 수정") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(
                    with: MatchEndpoints.update(matchId: id, title: "수정된 경기", ifMatch: ifMatchText)
                )
            }
            row("[SET-10] 경기 준비 완료") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchEndpoints.ready(matchId: id, ifMatch: ifMatchText))
            }
            row("[SET-11] 경기 취소") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchEndpoints.cancel(matchId: id, ifMatch: ifMatchText))
            }
            row("[GAME-01] 경기 시작") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchEndpoints.start(matchId: id, ifMatch: ifMatchText))
            }
            row("[GAME-12] 경기 종료") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchEndpoints.end(matchId: id, ifMatch: ifMatchText))
            }
        }
    }

    // MARK: - 쿼터 (SET-16~19, GAME-02,08~11,13,14)

    private var quarterSection: some View {
        Section("쿼터") {
            row("[SET-16] 쿼터 목록") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: QuarterEndpoints.list(matchId: id))
            }
            row("[SET-17] 쿼터 추가") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.create(matchId: id, durationSeconds: parsedInt(durationSecondsText) ?? 600, ifMatch: ifMatchText)
                )
            }
            row("[SET-18] 쿼터 시간 수정") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.updateDuration(matchId: mid, quarterId: qid, durationSeconds: parsedInt(durationSecondsText) ?? 600, ifMatch: ifMatchText)
                )
            }
            row("[SET-19] 쿼터 삭제") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                try await NetworkService.provider.requestWithoutResponse(
                    with: QuarterEndpoints.delete(matchId: mid, quarterId: qid, ifMatch: ifMatchText)
                )
                return "OK"
            }
            row("[GAME-02] 쿼터 시작") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.start(matchId: mid, quarterId: qid, ifMatch: ifMatchText)
                )
            }
            row("[GAME-08] 쿼터 측정 마감") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.endMeasurement(matchId: mid, quarterId: qid, ifMatch: ifMatchText)
                )
            }
            row("[GAME-11] 쿼터 완료 확정") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.complete(matchId: mid, quarterId: qid, ifMatch: ifMatchText)
                )
            }
            row("[GAME-09] 대표 포지션 조회") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterEndpoints.position(matchId: mid, quarterId: qid))
            }
            row("[GAME-10] 대표 포지션 저장") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.setPosition(matchId: mid, quarterId: qid, positionCode: positionCodeText, ifMatch: ifMatchText)
                )
            }
            row("[GAME-13] 골·어시스트 조회") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterEndpoints.stats(matchId: mid, quarterId: qid))
            }
            row("[GAME-14] 골·어시스트 저장") {
                let mid = try requiredUUID(matchIdText, "matchId")
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterEndpoints.setStats(
                        matchId: mid, quarterId: qid,
                        goals: parsedInt(goalsText) ?? 0, assists: parsedInt(assistsText) ?? 0,
                        ifMatch: ifMatchText
                    )
                )
            }
        }
    }

    // MARK: - 쿼터 운동기록 (WORK-01~07)

    private var quarterWorkoutSection: some View {
        Section("쿼터 운동기록") {
            row("[WORK-01] 운동 원본 업로드") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                let payload = WorkoutPayload(
                    startDate: Date().addingTimeInterval(-600),
                    endDate: Date(),
                    points: [],
                    heartRateSamples: [],
                    totalCalories: 0,
                    totalDistance: 0
                )
                return try await NetworkService.provider.request(
                    with: QuarterWorkoutEndpoints.uploadPayload(quarterId: qid, payload: payload, ifMatch: ifMatchText)
                )
            }
            row("[WORK-02] 저장 운동 기본값") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterWorkoutEndpoints.workout(quarterId: qid))
            }
            row("[WORK-03] 운동 요약 조회") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterWorkoutEndpoints.summary(quarterId: qid))
            }
            row("[WORK-04] GPS 원본 페이지") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterWorkoutEndpoints.trackPoints(quarterId: qid))
            }
            row("[WORK-05] 심박 원본 페이지") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: QuarterWorkoutEndpoints.heartRateSamples(quarterId: qid))
            }
            row("[WORK-06] 최대심박수 설정") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterWorkoutEndpoints.updateSummarySettings(quarterId: qid, hrMaxReferenceBpm: parsedDouble(hrMaxText) ?? 190, ifMatch: ifMatchText)
                )
            }
            row("[WORK-07] 운동 요약 재계산") {
                let qid = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(
                    with: QuarterWorkoutEndpoints.recalculateSummary(quarterId: qid, ifMatch: ifMatchText)
                )
            }
        }
    }

    // MARK: - 경기 결과 (RESULT-01,03,04)

    private var matchResultSection: some View {
        Section("경기 결과") {
            row("[RESULT-01] 개인 경기 결과") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchResultEndpoints.matchResult(matchId: id))
            }
            row("[RESULT-03] 쿼터별 결과 목록") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(with: MatchResultEndpoints.quarterResults(matchId: id))
            }
            row("[RESULT-04] 개별 쿼터 결과") {
                let id = try requiredUUID(quarterIdText, "quarterId")
                return try await NetworkService.provider.request(with: MatchResultEndpoints.quarterResult(quarterId: id))
            }
        }
    }

    // MARK: - 분석 (STAT-01~05)

    private var analyticsSection: some View {
        Section("분석") {
            row("[STAT-01] 요약 지표") {
                try await NetworkService.provider.request(
                    with: AnalyticsEndpoints.summary(from: optionalText(fromText), to: optionalText(toText), subjectUserId: try optionalUUID(subjectUserIdText))
                )
            }
            row("[STAT-02] 지표 추세") {
                try await NetworkService.provider.request(
                    with: AnalyticsEndpoints.trends(
                        metric: metricText, bucket: .day,
                        from: optionalText(fromText), to: optionalText(toText),
                        subjectUserId: try optionalUUID(subjectUserIdText)
                    )
                )
            }
            row("[STAT-03] 경기 간 비교") {
                let id = try requiredUUID(matchIdText, "matchId")
                return try await NetworkService.provider.request(
                    with: AnalyticsEndpoints.matchComparison(matchId: id, previousMatchId: try optionalUUID(previousMatchIdText), metric: metricText)
                )
            }
            row("[STAT-04] 포지션 분석") {
                try await NetworkService.provider.request(
                    with: AnalyticsEndpoints.positions(from: optionalText(fromText), to: optionalText(toText), subjectUserId: try optionalUUID(subjectUserIdText))
                )
            }
            row("[STAT-05] 친구와 비교") {
                let id = try requiredUUID(targetUserIdText, "상대 userId")
                return try await NetworkService.provider.request(
                    with: AnalyticsEndpoints.friendComparison(friendUserId: id, metric: metricText, from: optionalText(fromText), to: optionalText(toText))
                )
            }
        }
    }

    // MARK: - NOTI-03/04/05는 별도 입력칸이 없어 기존 칸을 임시로 재사용한다.

    private var notificationIdPlaceholder: String { requestIdText }
    private var deviceIdPlaceholder: String { quarterIdText }

    // MARK: - 입력 파싱 헬퍼

    private func requiredUUID(_ text: String, _ field: String) throws -> UUID {
        guard let uuid = UUID(uuidString: text.trimmingCharacters(in: .whitespaces)) else {
            throw TestInputError.missing(field)
        }
        return uuid
    }

    private func optionalUUID(_ text: String) throws -> UUID? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard let uuid = UUID(uuidString: trimmed) else { throw TestInputError.invalid("UUID") }
        return uuid
    }

    private func optionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parsedInt(_ text: String) -> Int? { Int(text.trimmingCharacters(in: .whitespaces)) }
    private func parsedDouble(_ text: String) -> Double? { Double(text.trimmingCharacters(in: .whitespaces)) }

    private func row<T>(_ title: String, _ call: @escaping () async throws -> T) -> some View {
        APIRow(title: title, action: {
            let value = try await call()
            return "\(value)"
        })
    }
}

private enum TestInputError: Error, CustomStringConvertible {
    case missing(String)
    case invalid(String)

    var description: String {
        switch self {
        case .missing(let field): return "⚠️ \(field) 값을 입력해주세요"
        case .invalid(let field): return "⚠️ \(field) 형식이 올바르지 않아요"
        }
    }
}

private struct APIRow: View {
    let title: String
    let action: () async throws -> String

    @State private var status: Status = .idle
    @State private var detail: String = ""

    private enum Status { case idle, loading, success, failure }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                icon
                Text(title)
                    .font(.footnote)
                Spacer()
                Button("실행") { run() }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .disabled(status == .loading)
            }
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(status == .failure ? .red : .secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var icon: some View {
        switch status {
        case .idle:
            Image(systemName: "circle").foregroundStyle(.gray).font(.caption2)
        case .loading:
            ProgressView().scaleEffect(0.6)
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption2)
        case .failure:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption2)
        }
    }

    private func run() {
        status = .loading
        Task {
            do {
                detail = try await action()
                status = .success
            } catch {
                detail = "\(error)"
                status = .failure
            }
        }
    }
}

#Preview {
    NavigationStack {
        NetworkTestView()
    }
}
#endif
