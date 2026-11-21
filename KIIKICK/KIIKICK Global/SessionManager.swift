//
//  SessionManager.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 10/27/26.
//

import CoreLocation
import SwiftData
import WatchConnectivity

@Observable
final class SessionManager: NSObject {
    
    static let shared = SessionManager()
    
    var isReachable: Bool = false
    var isMatchInProgress: Bool = false
    /// iOS에서 경기를 생성할 때(운동장을 고를 때) 채워지고, 경기가 끝나면 다시 nil로
    /// 돌아간다 — 워치의 "경기 시작" 화면이 다음 경기 전까지는 대기 화면을 보여주는 데 쓴다.
    var preparedFieldName: String?
    /// 이슈 #50 — iOS에서 "강제로 경기 종료하기"를 누르면 현재 시각(epoch seconds)으로
    /// 채워진다. 값 자체가 아니라 "바뀌었다"는 이벤트로 쓴다 — 매번 새 타임스탬프를
    /// 보내기 때문에, 워치는 이전에 처리한 값보다 큰(새로운) 값이 왔을 때만 반응한다
    /// (MainView.handleForceEnd 참고). applicationContext에 남아있는 옛 값을 다음 경기
    /// 시작 때 잘못 재생하지 않도록 하는 가드도 그쪽에 있다.
    var forceEndRequestedAt: TimeInterval?

    #if os(iOS)
    var modelContext: ModelContext?
    /// 워치가 가장 최근에 보내온 기록. didReceive(file:)에서 .myPlay 알림을 만드는 데 쓴다.
    var justArrivedRecord: WorkoutRecord?
    /// 알림 목록 — 비어서 시작하고, 경기 분석 결과가 도착하면(아래 didReceive(file:))
    /// .myPlay 알림을 맨 앞에 추가한다. 실제 서버/로컬 저장소가 없어서 앱을 다시 켜면
    /// 그동안 쌓인 알림도 같이 사라진다 — DESIGN-GAP.
    var notifications: [NotificationItem] = []
    /// 이슈 #66: 경기 준비할 때 고른 실제 Field. preparedFieldName은 워치에 보여줄
    /// "이름" 문자열만 들고 있어서, 쿼터가 도착할 때(didReceive(file:)) WorkoutRecord에
    /// 그대로 이어줄 참조가 따로 필요했다. 경기가 "시작"될 때는(preparedFieldName과
    /// 달리) 지우지 않는다 — 쿼터들은 경기가 진행 중일 때 하나씩 도착하므로 그때까지
    /// 들고 있어야 한다. 다음 경기를 준비하면 그냥 덮어써진다.
    var preparedField: Field?
    #endif

    #if os(watchOS)
    enum TransferStatus: Equatable {
        case idle
        case sending(pointCount: Int)
        case success(pointCount: Int)
        case failure(String)
    }
    var transferStatus: TransferStatus = .idle
    var modelContext: ModelContext?
    private var pendingPointCount: Int = 0

    func beginTransfer(pointCount: Int) {
        pendingPointCount = pointCount
        DispatchQueue.main.async { self.transferStatus = .sending(pointCount: pointCount) }
    }

    /// 경기 시작/종료 시점에 호출해서 iPhone 쪽에 현재 경기 진행 여부를 알린다. 두 경로
    /// 모두 iOS 쪽의 같은 키("isMatchInProgress")를 읽는다.
    func updateMatchStatus(isInProgress: Bool) {
        isMatchInProgress = isInProgress
        sendContextUpdate(["isMatchInProgress": isInProgress])
    }

    /// `recordID`를 넘기면, 이 전송이 성공했을 때 같은 id의 `QuarterRecord`만 지운다.
    /// (쿼터 하나 = WorkoutPayload 하나라서, 쿼터가 끝날 때마다 바로 보낸다.)
    func send(payload: WorkoutPayload, recordID: UUID? = nil) {
        do {
            let data = try JSONEncoder().encode(payload)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            try data.write(to: url)
            beginTransfer(pointCount: payload.points.count)
            let metadata = recordID.map { ["quarterRecordID": $0.uuidString] }
            WCSession.default.transferFile(url, metadata: metadata)
        } catch {
            DispatchQueue.main.async { self.transferStatus = .failure(error.localizedDescription) }
        }
    }
    #endif

    #if os(iOS)
    /// 운동장을 골라 경기를 "생성"할 때 호출해서 워치에 알린다. `field`가 nil이면
    /// "아직 준비 안 됨" — 워치 StartView가 대기 화면을 보여준다. 이름만 워치로
    /// 보내고, Field 참조 자체는 preparedField로 들고 있다가 쿼터가 도착하면
    /// WorkoutRecord.field로 이어준다(이슈 #66).
    func updateMatchPrepared(field: Field?) {
        preparedField = field
        preparedFieldName = field?.name
        sendContextUpdate(["preparedFieldName": field?.name ?? ""])
    }

    /// 경기가 시작돼서 워치 쪽 "준비됨" 표시만 되돌릴 때 쓴다. preparedField는 그대로
    /// 둔다 — 쿼터들이 경기 진행 중에 하나씩 도착하므로(didReceive(file:)) 그때까지
    /// Field 참조가 필요하다.
    func clearPreparedFieldDisplay() {
        preparedFieldName = nil
        sendContextUpdate(["preparedFieldName": ""])
    }

    /// "강제로 경기 종료하기" 버튼에서 호출한다. 워치가 지금 어느 단계에 있든(쿼터 진행 중,
    /// 포지션 선택 중, 인터벌 중) 즉시 경기를 끝내라는 신호다. iOS는 이 경기가 실제로
    /// 끝났는지 알 수 없으니 여기서 isMatchInProgress를 직접 바꾸지 않는다 — 워치가
    /// 처리를 마치면 평소처럼 updateMatchStatus(isInProgress: false)로 알려온다.
    func requestForceEndMatch() {
        sendContextUpdate(["forceEndRequestedAt": Date().timeIntervalSince1970])
    }
    #endif

    /// `sendMessage`(reachable일 때 즉시) + `updateApplicationContext`(백그라운드에서도 전달)
    /// 둘 다로 보낸다. `updateApplicationContext`는 컨텍스트 전체를 통째로 덮어쓰기 때문에,
    /// 기존 컨텍스트에 새 값만 합쳐서 보내야 다른 키(예: isMatchInProgress)가 안 날아간다.
    private func sendContextUpdate(_ payload: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                #if DEBUG
                print("[SessionManager] sendMessage 실패 - \(error)")
                #endif
            }
        }

        var context = WCSession.default.applicationContext
        for (key, value) in payload { context[key] = value }
        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            #if DEBUG
            print("[SessionManager] updateApplicationContext 실패 - \(error)")
            #endif
        }
    }

    private override init() {
        super.init()
        guard WCSession.isSupported() else {
            #if DEBUG
            print("[SessionManager] WCSession is not supported on this device.")
            #endif
            return
        }
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            #if DEBUG
            print("[SessionManager] SwiftUI Preview에서는 WCSession을 활성화하지 않음.")
            #endif
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension SessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
        #if os(iOS)
        // 앱이 늦게 켜져서 activate 전에 이미 워치가 context를 갱신해놨을 수 있으니 시작 시점에 한 번 읽어둔다.
        if let isInProgress = session.receivedApplicationContext["isMatchInProgress"] as? Bool {
            DispatchQueue.main.async { self.isMatchInProgress = isInProgress }
        }
        #endif
        #if os(watchOS)
        // 반대 방향 — 워치 앱이 늦게 켜져서 activate 전에 이미 iOS가 경기를 준비해놨을 수 있다.
        if let fieldName = session.receivedApplicationContext["preparedFieldName"] as? String {
            DispatchQueue.main.async { self.preparedFieldName = fieldName.isEmpty ? nil : fieldName }
        }
        // 워치 앱이 강제 종료 요청 이후에 재시작됐을 수도 있다 — baseline보다 새 값이면
        // MainView.handleForceEnd가 반응한다. 옛 값이면(이미 처리했거나 이전 경기 것) 무시된다.
        if let forceEndRequestedAt = session.receivedApplicationContext["forceEndRequestedAt"] as? TimeInterval {
            DispatchQueue.main.async { self.forceEndRequestedAt = forceEndRequestedAt }
        }
        #endif
        #if DEBUG
        if let error {
            print("[SessionManager] 활성화 실패 - \(error)")
        } else {
            print("[SessionManager] 활성화 완료 - state: \(activationState.rawValue)")
            #if os(watchOS)
            print("[SessionManager] isReachable: \(session.isReachable), 대기중인 큐: \(session.outstandingFileTransfers.count)개")
            #endif
        }
        #endif
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        #if os(iOS)
        
        #endif
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        #if os(iOS)
        guard let data = try? Data(contentsOf: file.fileURL),
              let payload = try? JSONDecoder().decode(WorkoutPayload.self, from: data) else {
            #if DEBUG
            print("[SessionManager] 수신 파일 디코딩 실패")
            #endif
            return
        }
        let record = WorkoutRecord(payload: payload)
        DispatchQueue.main.async {
            // 이슈 #66: 경기 준비할 때 고른 Field를 이 쿼터에도 그대로 이어준다 —
            // 전에는 아무도 WorkoutRecord.field를 세팅하지 않아서(WorkoutDetailView의
            // 수동 선택 말고는) workout-submissions에 보낼 field가 항상 비어 있었다.
            record.field = self.preparedField
            self.modelContext?.insert(record)
            try? self.modelContext?.save()
            self.justArrivedRecord = record
            // 홈 화면에 배너를 따로 띄우지 않고, 알림으로만 "분석 결과가 도착했어요"를 알린다.
            self.notifications.insert(
                NotificationItem(date: Date(), kind: .myPlay(record: record), isRead: false),
                at: 0
            )
        }
        #endif
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyMatchStatus(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyMatchStatus(from: message)
    }

    private func applyMatchStatus(from payload: [String: Any]) {
        if let isInProgress = payload["isMatchInProgress"] as? Bool {
            DispatchQueue.main.async {
                #if DEBUG
                print("[SessionManager] isMatchInProgress 수신 - \(isInProgress)")
                #endif
                self.isMatchInProgress = isInProgress
            }
        }
        if let fieldName = payload["preparedFieldName"] as? String {
            DispatchQueue.main.async {
                #if DEBUG
                print("[SessionManager] preparedFieldName 수신 - \(fieldName)")
                #endif
                self.preparedFieldName = fieldName.isEmpty ? nil : fieldName
            }
        }
        if let forceEndRequestedAt = payload["forceEndRequestedAt"] as? TimeInterval {
            DispatchQueue.main.async {
                #if DEBUG
                print("[SessionManager] forceEndRequestedAt 수신 - \(forceEndRequestedAt)")
                #endif
                self.forceEndRequestedAt = forceEndRequestedAt
            }
        }
    }

    #if os(watchOS)
    func session(_ session: WCSession,
                 didFinish fileTransfer: WCSessionFileTransfer,
                 error: Error?) {
        let recordIDString = fileTransfer.file.metadata?["quarterRecordID"] as? String
        DispatchQueue.main.async {
            if let error {
                self.transferStatus = .failure(error.localizedDescription)
            } else {
                self.transferStatus = .success(pointCount: self.pendingPointCount)
                if let recordIDString, let recordID = UUID(uuidString: recordIDString) {
                    self.deleteQuarterRecord(id: recordID)
                }
            }
        }
    }

    /// 전송이 끝난 쿼터 기록은 워치에 남겨둘 필요가 없어서 같은 id의 기록만 지운다.
    private func deleteQuarterRecord(id: UUID) {
        guard let modelContext else { return }
        do {
            let descriptor = FetchDescriptor<QuarterRecord>(predicate: #Predicate { $0.id == id })
            for record in try modelContext.fetch(descriptor) {
                modelContext.delete(record)
            }
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[SessionManager] 전송 완료 기록 삭제 실패 - \(error)")
            #endif
        }
    }
    #endif
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
