//
//  LoginView.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("KIIKICK")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // 비밀번호 등 실제 로그인 수단이 아직 없어서(서버가 userId로만 소유자를 구분) 비활성화해둠.
                Button("로그인") {}
                    .buttonStyle(.bordered)
                    .disabled(true)

                NavigationLink("회원가입") {
                    SignUpView()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
        .environment(AppRouter())
}
