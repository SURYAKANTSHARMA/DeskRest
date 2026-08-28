//
//  DashboardViewModel.swift
//  DeskReset
//

import Foundation
import Observation
import SwiftData
import OSLog

struct DailyHistoryReport: Identifiable, Sendable {
    var id: Date { date }
    let date: Date
    let averageScore: Int
    let totalScans: Int
    let topIssue: String?
    let topIssueIcon: String?
}

struct RecommendationItem: Identifiable, Sendable {
    var id: String { title }
    let title: String
    let isGood: Bool
    let details: String
}

struct CategoryRate: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let shortName: String
    let goodRate: Double   // 0.0 – 1.0
}

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Card & Recommendation State

    /// Card 1: Current Status
    var currentStatus: String        = "Ready"
    var currentStatusIcon: String    = "checkmark.circle.fill"
    var currentStatusColor: String   = "statusSuccess"   // semantic name
    var currentStatusDetail: String  = "System is idle"

    /// Card 2: Today's Score
    var todayScore: Int              = 0
    var averageScore: Int            = 0
    var todayScoreLabel: String      = "—"
    var todayScoreProgress: Double   = 0.0
    var scoreSessionCount: Int       = 0

    /// Card 3: Monitoring State
    var monitoringState: MonitoringState = .inactive
    var monitoringUptime: String     = "—"
    var monitoringSince: Date?       = nil

    /// Card 5: Last Check Time
    var lastCheckTime: Date?         = nil
    var lastCheckDisplay: String     = "Never"
    var nextCheckIn: String          = "—"
    var totalChecks: Int             = 0
    var lastScanFeedback: String     = "Waiting for first scan..."

    // MARK: - Posture Recommendations (directly on dashboard)
    var lastCheckRecommendations: [RecommendationItem] = []
    var overallStrength: String = "No checks recorded yet"
    var overallStruggle: String = "No issues recorded yet"
    var overallWorkspaceAdvice: String = "Start monitoring to receive workstation setup advice."
    var todayScansCount: Int = 0
    var todayAwayCount: Int = 0
    /// Per-category performance across all of today's valid scans
    var categoryRates: [CategoryRate] = []

    /// Data-driven AI coaching guidance synthesizing historical logs and ergonomic fixes
    var aiCoachGuidance: AICoachGuidance? = nil

    /// How the last scan score compares to today's average (positive = above avg)
    var scoreTrendVsAverage: Int { todayScore - averageScore }

    // MARK: - History Stats
    var totalScansCount: Int = 0
    var averagePostureScore: Int = 0
    var dailyReports: [DailyHistoryReport] = []

    // MARK: - Other State
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
            if todayScore >= 60 { return "Good work — stay consistent." }
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
    private var postureService: (any PostureServiceProtocol)?
    private var ergonomicAdvisorService: (any ErgonomicAdvisorServiceProtocol)?
    private var uiTimer: Timer?

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.postureService = serviceLocator.postureService
        self.ergonomicAdvisorService = serviceLocator.ergonomicAdvisorService
        Logger.ui.info("DashboardViewModel configured")
        refreshMonitoringState()
    }

    // MARK: - Load from SwiftData

    func loadStats(modelContext: ModelContext) {
        isLoading = true
        do {
            let calendar = Calendar.current

            // Load UserPreferences baseline
            let prefDescriptor = FetchDescriptor<UserPreferences>()
            let prefsList = try modelContext.fetch(prefDescriptor)
            let prefs = prefsList.first ?? UserPreferences()
            isCalibrated = prefs.isCalibrated
            postureService?.updateBaseline(prefs.baseline)
            postureService?.monitoringInterval = prefs.monitoringInterval

            // Fetch posture logs
            let logDescriptor = FetchDescriptor<PostureLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            let allLogs = (try? modelContext.fetch(logDescriptor)) ?? []
            let todayLogs = allLogs.filter { calendar.isDateInToday($0.timestamp) && $0.issuesSummary != "Away" }
            let todayAwayLogs = allLogs.filter { calendar.isDateInToday($0.timestamp) && $0.issuesSummary == "Away" }
            
            // Update feedback and last status
            if let ps = postureService {
                if ps.lastRunStatus == .personNotDetected {
                    lastScanFeedback = "No person detected in frame"
                } else if let lastLog = todayLogs.first, let feedback = lastLog.issuesSummary {
                    lastScanFeedback = feedback
                } else {
                    lastScanFeedback = "Waiting for first scan..."
                }
            } else {
                lastScanFeedback = "Service offline"
            }
            
            let latestScore: Int
            let avgScore: Int
            
            if let ps = postureService, ps.lastRunStatus == .personNotDetected {
                latestScore = 0
                avgScore = todayLogs.isEmpty ? 0 : todayLogs.reduce(0) { $0 + $1.score } / todayLogs.count
            } else if let firstLog = todayLogs.first {
                latestScore = firstLog.score
                avgScore = todayLogs.reduce(0) { $0 + $1.score } / todayLogs.count
            } else if let ps = postureService, ps.isMonitoring {
                latestScore = ps.postureScore
                avgScore = ps.postureScore
            } else {
                latestScore = 0
                avgScore = 0
            }
            
            todayScore = latestScore
            averageScore = avgScore
            todayScoreProgress = Double(todayScore) / 100.0
            todayScoreLabel = scoreLabel(todayScore)
            todayScansCount = todayLogs.count
            todayAwayCount = todayAwayLogs.count

            // History tab: scans & daily reports (excluding Away logs)
            let validLogs = allLogs.filter { $0.issuesSummary != "Away" }
            totalScansCount = validLogs.count
            averagePostureScore = validLogs.isEmpty ? 0 : validLogs.reduce(0) { $0 + $1.score } / validLogs.count

            // Group logs by day
            let logsByDate = Dictionary(grouping: allLogs) { log in
                calendar.startOfDay(for: log.timestamp)
            }
            let sortedDates = logsByDate.keys.sorted(by: >)

            dailyReports = sortedDates.compactMap { date in
                let dayLogs = logsByDate[date] ?? []
                let validDayLogs = dayLogs.filter { $0.issuesSummary != "Away" }
                if validDayLogs.isEmpty { return nil }
                
                let avg = validDayLogs.reduce(0) { $0 + $1.score } / validDayLogs.count
                
                // Identify top issue for that day
                var issueCounts: [String: Int] = [:]
                var issueIcons: [String: String] = [:]
                
                for log in validDayLogs {
                    if let summary = log.issuesSummary, !summary.isEmpty, !summary.contains("Great posture") && !summary.contains("No issues") {
                        let cleanSummary = summary.replacingOccurrences(of: "Detected: ", with: "")
                        let issueParts = cleanSummary.components(separatedBy: ", ")
                        for issueName in issueParts {
                            var trimmed = issueName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed == "Shoulder Imbalance" {
                                trimmed = "Uneven Shoulders"
                            }
                            if !trimmed.isEmpty {
                                issueCounts[trimmed, default: 0] += 1
                                if let issueType = PostureIssue.IssueType(rawValue: trimmed) {
                                    issueIcons[trimmed] = issueType.icon
                                }
                            }
                        }
                    }
                }
                
                let sortedIssues = issueCounts.sorted { $0.value > $1.value }
                let topIssue = sortedIssues.first?.key
                let topIcon = topIssue != nil ? issueIcons[topIssue!] : nil

                return DailyHistoryReport(
                    date: date,
                    averageScore: avg,
                    totalScans: validDayLogs.count,
                    topIssue: topIssue,
                    topIssueIcon: topIcon
                )
            }

            // Calculate direct dashboard recommendations
            calculateRecommendations(todayLogs: todayLogs, allLogs: allLogs)

        } catch {
            Logger.data.error("Dashboard loadStats error: \(error)")
            AnalyticsService.shared.recordError(error, context: ["operation": "DashboardViewModel.loadStats"])
            AnalyticsService.shared.log(.dataStoreError(operation: "DashboardViewModel.loadStats", error: error.localizedDescription))
        }
        isLoading = false
    }

    // MARK: - Calculate Recommendations

    private func calculateRecommendations(todayLogs: [PostureLog], allLogs: [PostureLog]) {
        guard let ps = postureService else { return }
        
        // 1. Generate full AI Coach Guidance
        if let advisor = ergonomicAdvisorService {
            let guidance = advisor.generateGuidance(
                todayLogs: todayLogs,
                allLogs: allLogs,
                currentAssessment: ps.currentAssessment,
                isMonitoring: ps.isMonitoring,
                isCalibrated: isCalibrated
            )
            self.aiCoachGuidance = guidance
            self.overallWorkspaceAdvice = guidance.ergonomicFixDetails
        }

        // 2. Last run recommendations
        if ps.lastRunStatus == .personNotDetected {
            lastCheckRecommendations = []
        } else if ps.lastRunStatus == .noScanYet {
            lastCheckRecommendations = []
        } else if let assessment = ps.currentAssessment {
            var items: [RecommendationItem] = []
            
            // Check Head Position
            let headIssue = assessment.issues.first(where: { $0.type == .forwardHead })
            items.append(RecommendationItem(
                title: "Head Alignment",
                isGood: headIssue == nil,
                details: headIssue?.description ?? "Head and neck vertically aligned"
            ))
            
            // Check Shoulders
            let shouldersIssue = assessment.issues.first(where: { $0.type == .shoulderImbalance })
            items.append(RecommendationItem(
                title: "Shoulder Level",
                isGood: shouldersIssue == nil,
                details: shouldersIssue?.description ?? "Shoulders level and balanced"
            ))
            
            // Check Upper Back
            let upperBackIssue = assessment.issues.first(where: { $0.type == .roundedShoulders })
            items.append(RecommendationItem(
                title: "Upper Back",
                isGood: upperBackIssue == nil,
                details: upperBackIssue?.description ?? "Chest open, shoulders rolled back"
            ))
            
            // Check Torso
            let torsoIssue = assessment.issues.first(where: { $0.type == .torsoLean })
            items.append(RecommendationItem(
                title: "Torso Center",
                isGood: torsoIssue == nil,
                details: torsoIssue?.description ?? "Torso straight and centered"
            ))
            
            lastCheckRecommendations = items
        } else {
            lastCheckRecommendations = []
        }
        
        // 3. Overall trend recommendations (using all of today's logs)
        if todayLogs.isEmpty {
            overallStrength = "—"
            overallStruggle = "—"
            return
        }
        
        var headCorrect = 0
        var shouldersCorrect = 0
        var upperBackCorrect = 0
        var torsoCorrect = 0
        
        var headIssuesCount = 0
        var shouldersIssuesCount = 0
        var upperBackIssuesCount = 0
        var torsoIssuesCount = 0
        
        let totalScansToday = todayLogs.count
        
        for log in todayLogs {
            let summary = log.issuesSummary ?? ""
            
            if summary.contains(PostureIssue.IssueType.forwardHead.rawValue) {
                headIssuesCount += 1
            } else {
                headCorrect += 1
            }
            
            if summary.contains(PostureIssue.IssueType.shoulderImbalance.rawValue) || summary.contains("Shoulder Imbalance") {
                shouldersIssuesCount += 1
            } else {
                shouldersCorrect += 1
            }
            
            if summary.contains(PostureIssue.IssueType.roundedShoulders.rawValue) {
                upperBackIssuesCount += 1
            } else {
                upperBackCorrect += 1
            }
            
            if summary.contains(PostureIssue.IssueType.torsoLean.rawValue) {
                torsoIssuesCount += 1
            } else {
                torsoCorrect += 1
            }
        }
        
        let categories = [
            ("Head Alignment", Double(headCorrect) / Double(totalScansToday)),
            ("Shoulder Level", Double(shouldersCorrect) / Double(totalScansToday)),
            ("Upper Back", Double(upperBackCorrect) / Double(totalScansToday)),
            ("Torso Center", Double(torsoCorrect) / Double(totalScansToday))
        ]

        let safe = Double(totalScansToday)
        categoryRates = [
            CategoryRate(name: "Head Alignment", shortName: "Head",      goodRate: Double(headCorrect)       / safe),
            CategoryRate(name: "Shoulder Level", shortName: "Shoulders", goodRate: Double(shouldersCorrect)  / safe),
            CategoryRate(name: "Upper Back",     shortName: "Back",      goodRate: Double(upperBackCorrect)  / safe),
            CategoryRate(name: "Torso Center",   shortName: "Torso",     goodRate: Double(torsoCorrect)      / safe),
        ]
        
        let sortedSuccess = categories.sorted { $0.1 > $1.1 }
        if let best = sortedSuccess.first {
            overallStrength = "\(best.0) (correct in \(Int(best.1 * 100))% of scans)"
        } else {
            overallStrength = "No data"
        }
        
        let struggles = [
            (PostureIssue.IssueType.forwardHead, headIssuesCount),
            (PostureIssue.IssueType.shoulderImbalance, shouldersIssuesCount),
            (PostureIssue.IssueType.roundedShoulders, upperBackIssuesCount),
            (PostureIssue.IssueType.torsoLean, torsoIssuesCount)
        ]
        
        let sortedStruggles = struggles.sorted { $0.1 > $1.1 }
        if let worst = sortedStruggles.first, worst.1 > 0 {
            let issueType = worst.0
            let percent = Int(Double(worst.1) / Double(totalScansToday) * 100)
            overallStruggle = "\(issueType.rawValue) (flagged in \(percent)% of scans)"
        } else {
            overallStruggle = "No posture issues detected today!"
        }
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
        
        AnalyticsService.shared.log(.monitoringStarted(isCalibrated: isCalibrated))
        AnalyticsService.shared.setCrashlyticsKey("monitoring_active", value: "true")
        
        uiTimer?.invalidate()
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshCurrentStatus()
            }
        }
    }

    func stopMonitoring() {
        let duration = monitoringSince != nil ? Int(Date.now.timeIntervalSince(monitoringSince!)) : 0
        AnalyticsService.shared.log(.monitoringStopped(durationSeconds: duration, scanCount: totalChecks))
        AnalyticsService.shared.setCrashlyticsKey("monitoring_active", value: "false")

        postureService?.stopMonitoring()
        monitoringState = .inactive
        monitoringUptime = "—"
        monitoringSince  = nil
        uiTimer?.invalidate()
        uiTimer = nil
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
        if let t = postureService?.nextCheckTime {
            let seconds = Int(t.timeIntervalSince(Date.now))
            if seconds > 0 {
                nextCheckIn = "in \(seconds)s"
            } else {
                nextCheckIn = "Checking now..."
                lastCheckTime = .now
            }
        } else {
            nextCheckIn = "—"
        }
        
        if let t = lastCheckTime {
            lastCheckDisplay = t.formatted(.relative(presentation: .named))
        } else {
            lastCheckDisplay = "Never"
        }
    }

    // MARK: - Actions

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
    case currentStatus, todayScore, monitoringState, lastCheckTime
}
