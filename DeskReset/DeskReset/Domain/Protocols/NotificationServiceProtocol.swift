//
//  NotificationServiceProtocol.swift
//  DeskReset
//

import Foundation

protocol NotificationServiceProtocol: AnyObject {
    var isAuthorized: Bool { get }

    func requestAuthorization() async -> Bool
    func scheduleBreakReminder(in seconds: TimeInterval, type: BreakType) async
    func cancelAllNotifications()
}
