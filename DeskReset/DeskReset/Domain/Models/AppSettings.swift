//
//  AppSettings.swift
//  DeskReset
//
//  Transient in-memory settings state (not persisted).
//  Used for ephemeral UI-driven state shared between views.
//

import Foundation

struct AppSettings: Equatable {
    var isDashboardVisible: Bool    = false
    var isBreakActive: Bool         = false
    var currentBreakType: BreakType = .short
    var appVersion: String          = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }()
    var buildNumber: String         = {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }()

    static let `default` = AppSettings()
}
