//
//  DevAuthView.swift
//  KIIKICK
//
//  테스트용 탭: 실제 로그인/스플래시 플로우를 거치지 않고도 Login/SignUp 화면을
//  바로 확인할 수 있게 해주고, 폰에 유저 토큰(UserId)이 있는지 색 버튼으로 보여준다.
//  DEBUG 빌드에서만 노출된다.
//

#if DEBUG
import SwiftUI

struct DevAuthView: View {
    @State private var isPresentingLogin = false
    @State private var isLoggedIn = UserSession.isLoggedIn

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

            Spacer()
        }
        .padding()
        .navigationTitle("로그인 (테스트)")
        .onAppear { isLoggedIn = UserSession.isLoggedIn }
        .sheet(isPresented: $isPresentingLogin) {
            LoginView()
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
