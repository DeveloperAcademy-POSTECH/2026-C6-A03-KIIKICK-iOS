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
    private var pendingPointCount: Int = 0
    
    func beginTransfer(pointCount: Int) {
        pendingPointCount = pointCount
        DispatchQueue.main.async { self.transferStatus = .sending(pointCount: pointCount) }
    }

    func send(payload: WorkoutPayload) {
        do {
            let data = try JSONEncoder().encode(payload)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            try data.write(to: url)
            beginTransfer(pointCount: payload.points.count)
            WCSession.default.transferFile(url, metadata: nil)
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
        DispatchQueue.main.async {
            if let error {
                self.transferStatus = .failure(error.localizedDescription)
            } else {
                self.transferStatus = .success(pointCount: self.pendingPointCount)
            }
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
