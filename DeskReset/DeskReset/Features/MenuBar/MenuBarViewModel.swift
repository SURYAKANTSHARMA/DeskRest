//
//  MenuBarViewModel.swift
//  DeskReset
//

import Foundation
import Observation
import OSLog

// MARK: — Monitoring State

enum MonitoringState: String, Equatable {
    case active   = "Active"
    case paused   = "Paused"
    case inactive = "Inactive"

    var icon: String {
        switch self {
        case .active:   return "eye.fill"
        case .paused:   return "eye.slash.fill"
        case .inactive: return "eye.slash"
        }
    }

    var tintColor: String {
        switch self {
        case .active:   return "statusSuccess"
        case .paused:   return "statusWarning"
        case .inactive: return "statusNeutral"
        }
    }
}

// MARK: — ViewModel

@Observable
@MainActor
final class MenuBarViewModel {

    // MARK: - Published State
    var monitoringState: MonitoringState = .inactive
    var postureScore: Int                = 0
    var lastCheckTime: Date?             = nil
    var recoverySessions: Int            = 0
    var statusMessage: String            = "Not monitoring"
    var todayScore: Int                  = 0

    // Derived
    var isMonitoring: Bool { monitoringState == .active }

    var lastCheckText: String {
        guard let t = lastCheckTime else { return "Never" }
        return t.formatted(.relative(presentation: .named))
    }

    var postureLabel: String {
        switch postureScore {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        case 1..<40:   return "Poor"
        default:       return "—"
        }
    }

    // MARK: - Private Services
    private var postureService: (any PostureServiceProtocol)?

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.postureService = serviceLocator.postureService
        Logger.ui.info("MenuBarViewModel configured")
    }

    // MARK: - Actions

    func startMonitoring() {
        postureService?.startMonitoring()
        monitoringState = .active
        statusMessage   = postureService?.statusDescription ?? "Monitoring active"
        lastCheckTime   = .now
        postureScore    = postureService?.postureScore ?? 100
        todayScore      = postureScore
        Logger.ui.info("MenuBar: startMonitoring()")
    }

    func stopMonitoring() {
        postureService?.stopMonitoring()
        monitoringState = .inactive
        statusMessage   = "Monitoring stopped"
        Logger.ui.info("MenuBar: stopMonitoring()")
    }

    func refreshPostureStatus() {
        guard let ps = postureService else { return }
        if ps.isMonitoring {
            monitoringState = .active
            postureScore    = ps.postureScore
            todayScore      = ps.postureScore
            statusMessage   = ps.statusDescription
        }
    }
}
