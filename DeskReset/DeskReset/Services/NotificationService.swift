//
//  NotificationService.swift
//  DeskReset
//
//  Placeholder implementation — notification scheduling not yet implemented.
//

import Foundation
import Observation
import UserNotifications
import OSLog

@Observable
final class NotificationService: NotificationServiceProtocol {

    // MARK: - State
    var isAuthorized: Bool = false

    // MARK: - Actions

    func requestAuthorization() async -> Bool {
        // TODO: Implement full authorisation flow with UNUserNotificationCenter
        Logger.notifications.info("NotificationService.requestAuthorization()")
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            Logger.notifications.info("Notification authorisation granted: \(granted)")
            if !granted {
                AnalyticsService.shared.log(.notificationPermissionDenied)
            }
            return granted
        } catch {
            Logger.notifications.error("Notification authorisation error: \(error)")
            AnalyticsService.shared.recordError(error, context: ["component": "NotificationService.requestAuthorization"])
            AnalyticsService.shared.log(.notificationPermissionDenied)
            return false
        }
    }

    func scheduleBreakReminder(in seconds: TimeInterval, type: BreakType) async {
        // TODO: Schedule UNTimeIntervalNotificationTrigger with break details
        Logger.notifications.info("scheduleBreakReminder — \(seconds)s, type: \(type.rawValue)")
    }

    func cancelAllNotifications() {
        // TODO: Implement selective cancellation
        Logger.notifications.info("NotificationService.cancelAllNotifications()")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
