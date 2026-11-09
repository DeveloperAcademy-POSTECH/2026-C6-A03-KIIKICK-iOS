//
//  DevAuthView.swift
//  KIIKICK
//
//  테스트용 탭: 실제 로그인/스플래시 플로우를 거치지 않고도 Login/SignUp 화면을
//  바로 확인할 수 있게 해주고, 폰에 유저 토큰(UserId)이 있는지 색 버튼으로 보여준다.
//  DEBUG 빌드에서만 노출된다.
//

#if DEBUG
import SwiftData
import SwiftUI

struct DevAuthView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingLogin = false
    @State private var isLoggedIn = UserSession.isLoggedIn
    @State private var fieldBackfillResultMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Button(isLoggedIn ? "토큰 있음 (탭하면 삭제)" : "토큰 없음") {
                UserSession.clear()
                isLoggedIn = UserSession.isLoggedIn
            }
            .disabled(!isLoggedIn)
            .buttonStyle(.borderedProminent)
            .tint(isLoggedIn ? .green : .red)

            Button("로그인 화면 보기") {
                isPresentingLogin = true
            }
            .buttonStyle(.bordered)

            NavigationLink("API 테스트") {
                NetworkTestView()
            }
            .buttonStyle(.bordered)

            // 이슈 #66: SessionManager.preparedField 연결 전에 기록된 WorkoutRecord는
            // field가 계속 nil이라 workout-submissions가 "field 없음"으로 거부한다.
            // 이미 등록된 "c5" Field를 그런 레코드에 수동으로 이어준다(1회성 데이터 보정).
            Button("field 없는 레코드 → \"c5\"로 연결") {
                backfillMissingField(named: "c5")
            }
            .buttonStyle(.bordered)
            if !fieldBackfillResultMessage.isEmpty {
                Text(fieldBackfillResultMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("로그인 (테스트)")
        .onAppear { isLoggedIn = UserSession.isLoggedIn }
        .sheet(isPresented: $isPresentingLogin) {
            NavigationStack {
                LoginView()
            }
        }
    }

    private func backfillMissingField(named fieldName: String) {
        guard let allFields = try? modelContext.fetch(FetchDescriptor<Field>()),
              let field = allFields.first(where: { $0.name.caseInsensitiveCompare(fieldName) == .orderedSame }) else {
            fieldBackfillResultMessage = "\"\(fieldName)\" 이름의 Field를 못 찾았어요"
            return
        }
        let recordDescriptor = FetchDescriptor<WorkoutRecord>()
        guard let records = try? modelContext.fetch(recordDescriptor) else {
            fieldBackfillResultMessage = "WorkoutRecord 조회 실패"
            return
        }
        let targets = records.filter { $0.field == nil }
        targets.forEach { $0.field = field }
        do {
            try modelContext.save()
            fieldBackfillResultMessage = "\(targets.count)개 레코드에 \"\(fieldName)\" 연결 완료"
        } catch {
            fieldBackfillResultMessage = "저장 실패: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        DevAuthView()
            .environment(AppRouter())
    }
}
#endif
