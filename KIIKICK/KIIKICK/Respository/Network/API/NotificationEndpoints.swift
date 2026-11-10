//
//  NotificationEndpoints.swift
//  KIIKICK
//
//  백엔드 docs/api/notifications.md (NOTI-01~05) 기준.
//

import Foundation

enum NotificationEndpoints {
    private struct ListQuery: Encodable {
        let unreadOnly: Bool?
        let cursor: String?
        let limit: Int?
    }

    /// NOTI-01 알림 목록 조회
    static func list(unreadOnly: Bool? = nil, cursor: String? = nil, limit: Int? = nil) -> Endpoint<PageEnvelope<NotificationResponse>> {
        Endpoint(
            path: "/api/v1/notifications",
            method: .get,
            queryParameters: ListQuery(unreadOnly: unreadOnly, cursor: cursor, limit: limit),
            headers: bearerHeaders()
        )
    }

    /// NOTI-02 읽지 않은 알림 수 조회
    static func unreadCount() -> Endpoint<Envelope<UnreadCountResponse>> {
        Endpoint(path: "/api/v1/notifications/unread-count", method: .get, headers: bearerHeaders())
    }

    /// NOTI-03 알림 읽음 처리
    static func markRead(notificationId: UUID, idempotencyKey: UUID = UUID()) -> Endpoint<Envelope<NotificationResponse>> {
        Endpoint(
            path: "/api/v1/notifications/\(notificationId.uuidString)/read",
            method: .put,
            headers: bearerHeaders().merging(idempotencyHeaders(idempotencyKey)) { _, new in new }
        )
    }

    /// NOTI-04 기기 등록·푸시 설정 갱신
    static func updateDevice(
        deviceId: UUID,
        platform: DevicePlatform,
        pushToken: String?,
        pushEnabled: Bool
    ) -> Endpoint<Envelope<DeviceResponse>> {
        Endpoint(
            path: "/api/v1/devices/\(deviceId.uuidString)",
            method: .put,
            bodyParameters: DeviceUpdateRequest(platform: platform, pushToken: pushToken, pushEnabled: pushEnabled),
            headers: idempotencyHeaders()
        )
    }

    /// NOTI-05 기기 등록 해제
    static func unregisterDevice(deviceId: UUID) -> Endpoint<Void> {
        Endpoint(
            path: "/api/v1/devices/\(deviceId.uuidString)",
            method: .delete,
            headers: idempotencyHeaders()
        )
    }
}
