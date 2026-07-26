//
//  AppLogger.swift
//  DeskReset
//
//  Structured logging using OSLog. Centralised logger instances per category.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.deskreset"

    /// General app lifecycle events.
    static let app = Logger(subsystem: subsystem, category: "App")
    /// SwiftUI view events.
    static let ui = Logger(subsystem: subsystem, category: "UI")
    /// SwiftData / persistence events.
    static let data = Logger(subsystem: subsystem, category: "Data")
    /// Service-layer events.
    static let services = Logger(subsystem: subsystem, category: "Services")
    /// Timer-related events.
    static let timer = Logger(subsystem: subsystem, category: "Timer")
    /// Notification events.
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
