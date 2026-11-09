//
//  NotificationDTO.swift
//  KIIKICK
//
//  백엔드 docs/api/notifications.md, docs/api/schemas.md의 Notification/Device/UnreadCount 기준.
//

import Foundation

struct NotificationTarget: Decodable {
    let type: String
    let id: UUID
}

struct NotificationResponse: Decodable, Identifiable {
    let id: UUID
    let type: String
    let title: String
    let body: String?
    let target: NotificationTarget
    let readAt: Date?
    let createdAt: Date
}

struct UnreadCountResponse: Decodable {
    let count: Int
}

enum DevicePlatform: String, Codable {
    case ios = "IOS"
    case watchOS = "WATCHOS"
}

struct DeviceUpdateRequest: Encodable {
    let platform: DevicePlatform
    let pushToken: String?
    let pushEnabled: Bool
}

struct DeviceResponse: Decodable {
    let id: UUID
    let platform: DevicePlatform
    let pushEnabled: Bool
    let lastSeenAt: Date
}
