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

    #if os(iOS)
    var modelContext: ModelContext?
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
            self.modelContext?.insert(record)
            try? self.modelContext?.save()
        }
        #endif
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
