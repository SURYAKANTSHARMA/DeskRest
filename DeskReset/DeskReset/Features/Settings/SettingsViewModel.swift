//
//  SettingsViewModel.swift
//  DeskReset
//

import Foundation
import Observation
import SwiftData
import OSLog

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - State (mirrors UserPreferences for editing)
    var breakInterval: Double        = 3600
    var shortBreakDuration: Double   = 300
    var longBreakDuration: Double    = 900
    var microBreakDuration: Double   = 90
    var defaultBreakType: BreakType  = .short
    var notificationsEnabled: Bool   = true
    var soundEnabled: Bool           = true
    var launchAtLogin: Bool          = false
    var showInDock: Bool             = false
    var dailyBreakGoal: Int          = 8
    var isSaving: Bool               = false

    // MARK: - Private Services
    private var notificationService: (any NotificationServiceProtocol)?

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.notificationService = serviceLocator.notificationService
    }

    // MARK: - Load from persistence

    func loadPreferences(modelContext: ModelContext) {
        do {
            let prefs = try modelContext.fetch(FetchDescriptor<UserPreferences>()).first
                ?? UserPreferences()
            breakInterval        = prefs.breakInterval
            shortBreakDuration   = prefs.shortBreakDuration
            longBreakDuration    = prefs.longBreakDuration
            microBreakDuration   = prefs.microBreakDuration
            defaultBreakType     = prefs.defaultBreakType
            notificationsEnabled = prefs.notificationsEnabled
            soundEnabled         = prefs.soundEnabled
            launchAtLogin        = prefs.launchAtLogin
            showInDock           = prefs.showInDock
            dailyBreakGoal       = prefs.dailyBreakGoal
        } catch {
            Logger.data.error("Failed to load preferences: \(error)")
        }
    }

    // MARK: - Save

    func savePreferences(modelContext: ModelContext) {
        isSaving = true
        do {
            let existing = try modelContext.fetch(FetchDescriptor<UserPreferences>()).first
            let prefs    = existing ?? UserPreferences()
            if existing == nil { modelContext.insert(prefs) }

            prefs.breakInterval        = breakInterval
            prefs.shortBreakDuration   = shortBreakDuration
            prefs.longBreakDuration    = longBreakDuration
            prefs.microBreakDuration   = microBreakDuration
            prefs.defaultBreakTypeRaw  = defaultBreakType.rawValue
            prefs.notificationsEnabled = notificationsEnabled
            prefs.soundEnabled         = soundEnabled
            prefs.launchAtLogin        = launchAtLogin
            prefs.showInDock           = showInDock
            prefs.dailyBreakGoal       = dailyBreakGoal

            try modelContext.save()
            Logger.data.info("Preferences saved successfully")
            AnalyticsService.shared.log(.settingsUpdated(settingName: "notifications_enabled", value: "\(notificationsEnabled)"))
            AnalyticsService.shared.log(.settingsUpdated(settingName: "sound_enabled", value: "\(soundEnabled)"))
            AnalyticsService.shared.log(.settingsUpdated(settingName: "launch_at_login", value: "\(launchAtLogin)"))
            AnalyticsService.shared.log(.settingsUpdated(settingName: "show_in_dock", value: "\(showInDock)"))
        } catch {
            Logger.data.error("Failed to save preferences: \(error)")
            AnalyticsService.shared.recordError(error, context: ["operation": "SettingsViewModel.savePreferences"])
            AnalyticsService.shared.log(.dataStoreError(operation: "savePreferences", error: error.localizedDescription))
        }
        isSaving = false
    }

    // MARK: - Notifications

    func requestNotificationPermission() async {
        let _ = await notificationService?.requestAuthorization()
    }

    // MARK: - Helpers

    func formatInterval(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        return mins >= 60 ? "\(mins / 60)h \(mins % 60)m" : "\(mins)m"
    }
}
