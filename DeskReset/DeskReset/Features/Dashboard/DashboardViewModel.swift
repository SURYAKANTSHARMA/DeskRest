//
//  DashboardViewModel.swift
//  DeskReset
//

import Foundation
import Observation
import SwiftData
import OSLog

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Card State (the 5 required cards)

    /// Card 1: Current Status
    var currentStatus: String        = "Ready"
    var currentStatusIcon: String    = "checkmark.circle.fill"
    var currentStatusColor: String   = "statusSuccess"   // semantic name
    var currentStatusDetail: String  = "System is idle"

    /// Card 2: Today's Score
    var todayScore: Int              = 0
    var todayScoreLabel: String      = "—"
    var todayScoreProgress: Double   = 0.0
    var scoreSessionCount: Int       = 0

    /// Card 3: Monitoring State
    var monitoringState: MonitoringState = .inactive
    var monitoringUptime: String     = "—"
    var monitoringSince: Date?       = nil

    /// Card 4: Recovery Sessions
    var recoverySessions: Int        = 0
    var recoveryGoal: Int            = 8
    var recoveryProgress: Double     = 0.0
    var lastRecovery: String         = "None today"

    /// Card 5: Last Check Time
    var lastCheckTime: Date?         = nil
    var lastCheckDisplay: String     = "Never"
    var nextCheckIn: String          = "—"
    var totalChecks: Int             = 0

    // MARK: - Other State
    var recentSessions: [BreakSession] = []
    var isLoading: Bool              = false
    var isCalibrated: Bool           = false
    var selectedCardID: DashboardCardID? = nil

    /// First-launch onboarding — persisted in UserDefaults
    var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "dr_onboarding_complete")

    // MARK: - Derived: Top Posture Issue (for Daily Summary card)
    var topPostureIssue: String? {
        if let issues = postureService?.currentAssessment?.issues, let top = issues.first {
            return top.type.rawValue
        }
        return nil
    }

    var topPostureIssueIcon: String? {
        if let issues = postureService?.currentAssessment?.issues, let top = issues.first {
            return top.type.icon
        }
        return nil
    }

    /// Context-aware motivational tip based on top posture issue or score.
    var motivationalTip: String {
        guard let issues = postureService?.currentAssessment?.issues, !issues.isEmpty else {
            if todayScore >= 80 { return "Excellent posture today! Keep it going." }
            if todayScore >= 60 { return "Good work — take a short break every hour." }
            if todayScore == 0  { return "Start monitoring to track your posture score." }
            return "Stay consistent — small improvements compound over time."
        }
        switch issues.first?.type {
        case .forwardHead:      return "Chin back — bring your head over your shoulders."
        case .roundedShoulders: return "Roll shoulders back and open your chest."
        case .shoulderImbalance: return "Check your seat height — keep both shoulders level."
        case .torsoLean:        return "Sit up straight — avoid leaning to one side."
        case .none:             return "Keep going — consistency is the key to good posture."
        }
    }

    // MARK: - Private Services
    private var breakService: (any BreakServiceProtocol)?
    private var postureService: (any PostureServiceProtocol)?

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.breakService  = serviceLocator.breakService
        self.postureService = serviceLocator.postureService
        Logger.ui.info("DashboardViewModel configured")
        refreshMonitoringState()
    }

    // MARK: - Load from SwiftData

    func loadStats(modelContext: ModelContext) {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<BreakSession>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            let allSessions = try modelContext.fetch(descriptor)
            let calendar    = Calendar.current
            let todaySessions = allSessions.filter { calendar.isDateInToday($0.startDate) }

            // Card 4: Recovery Sessions
            let completedToday = todaySessions.filter { $0.wasCompleted }
            recoverySessions   = completedToday.count
            recoveryProgress   = min(Double(recoverySessions) / Double(recoveryGoal), 1.0)
            lastRecovery       = completedToday.first.map {
                $0.startDate.formatted(.relative(presentation: .named))
            } ?? "None today"

            recentSessions = Array(allSessions.prefix(10))

            // Load UserPreferences baseline
            let prefDescriptor = FetchDescriptor<UserPreferences>()
            let prefsList = try modelContext.fetch(prefDescriptor)
            let prefs = prefsList.first ?? UserPreferences()
            isCalibrated = prefs.isCalibrated
            postureService?.updateBaseline(prefs.baseline)

            // Card 2: Real average score from PostureLogs
            let logDescriptor = FetchDescriptor<PostureLog>()
            let allLogs = (try? modelContext.fetch(logDescriptor)) ?? []
            let todayLogs = allLogs.filter { calendar.isDateInToday($0.timestamp) }
            
            let averageScore: Int
            if !todayLogs.isEmpty {
                averageScore = todayLogs.reduce(0) { $0 + $1.score } / todayLogs.count
            } else if let ps = postureService, ps.isMonitoring {
                averageScore = ps.postureScore
            } else {
                averageScore = 0
            }
            
            todayScore = averageScore
            todayScoreProgress = Double(todayScore) / 100.0
            todayScoreLabel = scoreLabel(todayScore)

        } catch {
            Logger.data.error("Dashboard loadStats error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Monitoring State Sync

    func refreshMonitoringState() {
        guard let ps = postureService else { return }
        monitoringState = ps.isMonitoring ? .active : .inactive

        if ps.isMonitoring, let since = monitoringSince {
            let elapsed = Int(Date.now.timeIntervalSince(since))
            let m = elapsed / 60; let h = m / 60
            monitoringUptime = h > 0 ? "\(h)h \(m % 60)m" : "\(m)m"
        } else {
            monitoringUptime = "—"
        }
        updateCurrentStatus()
    }

    func startMonitoring() {
        postureService?.startMonitoring()
        monitoringState  = .active
        monitoringSince  = .now
        lastCheckTime    = .now
        totalChecks     += 1
        refreshCurrentStatus()
    }

    func stopMonitoring() {
        postureService?.stopMonitoring()
        monitoringState = .inactive
        monitoringUptime = "—"
        monitoringSince  = nil
        refreshCurrentStatus()
    }

    private func refreshCurrentStatus() {
        refreshMonitoringState()
        updateLastCheck()
    }

    private func updateCurrentStatus() {
        switch monitoringState {
        case .active:
            currentStatus      = "Monitoring"
            currentStatusIcon  = "eye.fill"
            currentStatusColor = "statusSuccess"
            currentStatusDetail = "Posture detection running"
        case .paused:
            currentStatus      = "Paused"
            currentStatusIcon  = "pause.circle.fill"
            currentStatusColor = "statusWarning"
            currentStatusDetail = "Detection paused"
        case .inactive:
            currentStatus      = "Idle"
            currentStatusIcon  = "circle.dotted"
            currentStatusColor = "statusNeutral"
            currentStatusDetail = "Start monitoring to begin"
        }
    }

    private func updateLastCheck() {
        guard let t = lastCheckTime else {
            lastCheckDisplay = "Never"
            nextCheckIn      = "—"
            return
        }
        lastCheckDisplay = t.formatted(.relative(presentation: .named))
        nextCheckIn      = "~1 min"
        totalChecks     += 1
    }

    // MARK: - Actions

    func takeBreakNow() async {
        await breakService?.startBreak(type: .short)
        await breakService?.endBreak()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "dr_onboarding_complete")
        showOnboarding = false
    }

    // MARK: - Helpers

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        case 1..<40:   return "Needs Work"
        default:       return "No data"
        }
    }
}

// MARK: — Card IDs

enum DashboardCardID: String, Hashable {
    case currentStatus, todayScore, monitoringState, recoverySessions, lastCheckTime
}
