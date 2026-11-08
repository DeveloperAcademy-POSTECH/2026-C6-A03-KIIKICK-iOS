//
//  WaitingForMatchView.swift
//  KIIKICK Watch App Watch App
//
//  iOS에서 아직 경기를 생성(운동장 선택)하지 않았을 때 "경기 시작" 자리에 대신 뜨는
//  대기 화면. EndView의 "iPhone에서 경기를 준비해주세요" 문구와 같은 패턴이다 —
//  SessionManager.preparedFieldName이 nil인 동안은 계속 이 화면이고, iOS가
//  updateMatchPrepared(fieldName:)로 알려주면(= 운동장을 고르면) 자동으로
//  StartView로 바뀐다(MainView.swift 참고).
//

import SwiftUI

struct WaitingForMatchView: View {
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130)
            Text("iPhone에서\n경기를 준비해주세요")
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    WaitingForMatchView()
}
