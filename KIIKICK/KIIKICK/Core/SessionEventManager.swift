//
//  SessionEventManager.swift
//  KIIKICK
//
//  Created by Seungjun Lee on 11/18/26.
//

import Foundation

enum SessionEvent {
    case logout(reason: LogoutReason)
}

enum LogoutReason { case refreshTokenExpired, keychainWriteFailed }

final class SessionEventManager {
    static let shared = SessionEventManager()
    private init() {}
    private var continuation: AsyncStream<SessionEvent>.Continuation?
    lazy var events: AsyncStream<SessionEvent> = AsyncStream { self.continuation = $0 }
    func emit(_ event: SessionEvent) { continuation?.yield(event) }
}
