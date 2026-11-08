//
//  HomeMatchState.swift
//  KIIKICK
//
//  Figma "overall" 프레임 계열의 상단 배너 상태. 이슈 #42가 나열한 "워치 연결 여부 ×
//  기록 여부 × 경기 진행 상태" 조합을 하나의 enum으로 합쳤다.
//
//  우선순위(위에서부터 먼저 매칭되는 걸 쓴다): 경기 진행중 > 경기 준비됨 >
//  워치 연결 안 됨 > 기록 없음 > 평소(배너 없음). 이 순서는 HomeView.matchState에서 그대로
//  구현한다.
//
//  DESIGN-GAP: "기록 있음 + 워치 연결 X" 조합은 Figma "overall" 프레임 10개 중에
//  정확히 일치하는 샘플을 찾지 못했다 — 기록 유무와 무관하게 워치 연결 안내 문구를
//  그대로 재사용한다고 가정했다(watchDisconnected 케이스가 기록 유무를 안 가림).
//
//  원래 있던 justFinished(경기가 막 도착하면 뜨는 "새로운 분석지가 도착했어요" 배너)는
//  없앴다 — 이제 경기가 도착하면 배너 대신 알림(NotificationKind.myPlay)으로 뜨고,
//  홈 화면은 바로 idle로 넘어간다. SessionManager.didReceive(file:) 참고.
//
enum HomeMatchState: Equatable {
    /// 워치가 연결돼 있지 않음 — 기록이 있든 없든 이 안내가 최우선으로 뜬다(DESIGN-GAP 참고).
    case watchDisconnected
    /// 워치는 연결됨, 아직 기록이 하나도 없음.
    case noRecords
    /// 워치 연결됨 + 기록 있음, 평소 상태 — 배너 없이 Overall/통계만 보여준다.
    case idle
    case prepared(fieldName: String)
    case inProgress
}
