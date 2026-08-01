//
//  UserPreferences.swift
//  DeskReset
//
//  SwiftData model for persisted user preferences and posture baseline calibration.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {

    // MARK: - Break Intervals (seconds)
    var breakInterval: TimeInterval         // time between breaks
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var microBreakDuration: TimeInterval
    var defaultBreakTypeRaw: String
    var monitoringInterval: TimeInterval

    // MARK: - Notifications
    var notificationsEnabled: Bool
    var soundEnabled: Bool
    var reminderLeadSeconds: TimeInterval   // warn N seconds before break

    // MARK: - App Behaviour
    var launchAtLogin: Bool
    var showInDock: Bool
    var dailyBreakGoal: Int

    // MARK: - Posture Baseline Calibration (SwiftData Persisted)
    var isCalibrated: Bool
    var calibratedAt: Date?
    var baselineHeadOffset: Double
    var baselineShoulderTilt: Double
    var baselineTorsoLean: Double
    var baselineShoulderWidthRatio: Double

    // MARK: - Derived Properties

    var defaultBreakType: BreakType {
        BreakType(rawValue: defaultBreakTypeRaw) ?? .short
    }

    var baseline: PostureBaseline {
        get {
            PostureBaseline(
                isCalibrated: isCalibrated,
                calibratedAt: calibratedAt,
                headOffset: baselineHeadOffset,
                shoulderTilt: baselineShoulderTilt,
                torsoLean: baselineTorsoLean,
                shoulderWidthRatio: baselineShoulderWidthRatio
            )
        }
        set {
            isCalibrated = newValue.isCalibrated
            calibratedAt = newValue.calibratedAt
            baselineHeadOffset = newValue.headOffset
            baselineShoulderTilt = newValue.shoulderTilt
            baselineTorsoLean = newValue.torsoLean
            baselineShoulderWidthRatio = newValue.shoulderWidthRatio
        }
    }

    // MARK: - Init
    init() {
        self.breakInterval        = 3600        // 1 hour
        self.shortBreakDuration   = 300         // 5 min
        self.longBreakDuration    = 900         // 15 min
        self.microBreakDuration   = 90          // 1.5 min
        self.defaultBreakTypeRaw  = BreakType.short.rawValue
        self.monitoringInterval   = 90          // 90 seconds
        self.notificationsEnabled = true
        self.soundEnabled         = true
        self.reminderLeadSeconds  = 60
        self.launchAtLogin        = false
        self.showInDock           = false
        self.dailyBreakGoal       = 8

        // Calibration defaults
        self.isCalibrated               = false
        self.calibratedAt               = nil
        self.baselineHeadOffset         = 0.0
        self.baselineShoulderTilt       = 0.0
        self.baselineTorsoLean          = 0.0
        self.baselineShoulderWidthRatio = 1.0
    }
}
