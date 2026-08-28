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
    nonisolated static let app = Logger(subsystem: subsystem, category: "App")
    /// SwiftUI view events.
    nonisolated static let ui = Logger(subsystem: subsystem, category: "UI")
    /// SwiftData / persistence events.
    nonisolated static let data = Logger(subsystem: subsystem, category: "Data")
    /// Service-layer events.
    nonisolated static let services = Logger(subsystem: subsystem, category: "Services")
    /// Timer-related events.
    nonisolated static let timer = Logger(subsystem: subsystem, category: "Timer")
    /// Notification events.
    nonisolated static let notifications = Logger(subsystem: subsystem, category: "Notifications")
}
