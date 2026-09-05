//
//  AppRatingService.swift
//  DeskReset
//
//  Service managing app rating eligibility, StoreKit review triggers,
//  Mac App Store direct write-review links, and customer feedback routing.
//

import Foundation
import AppKit
import OSLog

// MARK: — App Rating Service

@Observable
final class AppRatingService {

    static let shared = AppRatingService()

    private let logger = Logger(subsystem: "com.deskreset.app", category: "Rating")

    // MARK: — App Store Configuration
    // Configurable App Store ID — update once live in App Store Connect
    var appStoreID: String = "6798651115"
    let supportEmail: String = "suryakantsharma84@gmail.com"

    // MARK: — UserDefaults Keys
    private enum Keys {
        static let hasRated                 = "dr_review_prompt_has_rated"
        static let declinedDate             = "dr_review_prompt_declined_date"
        static let lastVersionPrompted      = "dr_review_prompt_last_version"
        static let routinesCompletedCount   = "dr_review_prompt_routines_count"
        static let sessionsCompletedCount   = "dr_review_prompt_sessions_count"
    }

    // Cooldown duration: 30 days before asking again if dismissed
    private let cooldownInterval: TimeInterval = 30 * 24 * 60 * 60
    private let minRoutinesForPrompt: Int = 2
    private let minSessionsForPrompt: Int = 3

    private let userDefaults: UserDefaults

    // MARK: — State (UserDefaults backed)

    var hasRated: Bool {
        get { userDefaults.bool(forKey: Keys.hasRated) }
        set { userDefaults.set(newValue, forKey: Keys.hasRated) }
    }

    var declinedDate: Date? {
        get { userDefaults.object(forKey: Keys.declinedDate) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.declinedDate) }
    }

    var lastVersionPrompted: String? {
        get { userDefaults.string(forKey: Keys.lastVersionPrompted) }
        set { userDefaults.set(newValue, forKey: Keys.lastVersionPrompted) }
    }

    var routinesCompletedCount: Int {
        get { userDefaults.integer(forKey: Keys.routinesCompletedCount) }
        set { userDefaults.set(newValue, forKey: Keys.routinesCompletedCount) }
    }

    var sessionsCompletedCount: Int {
        get { userDefaults.integer(forKey: Keys.sessionsCompletedCount) }
        set { userDefaults.set(newValue, forKey: Keys.sessionsCompletedCount) }
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: — Milestone Tracking

    /// Call when the user completes an ergonomic recovery routine.
    func recordRoutineCompleted() {
        routinesCompletedCount += 1
        logger.info("Recorded routine completion. Total: \(self.routinesCompletedCount)")
    }

    /// Call when a break or posture monitoring session completes.
    func recordSessionCompleted() {
        sessionsCompletedCount += 1
        logger.info("Recorded session completion. Total: \(self.sessionsCompletedCount)")
    }

    // MARK: — Eligibility Check

    /// Evaluates whether it is appropriate to prompt the user for a rating.
    func shouldPromptForRating() -> Bool {
        // 1. If user already rated, never prompt automatically
        if hasRated {
            return false
        }

        // 2. Do not prompt more than once on the same app version
        if let lastVersion = lastVersionPrompted, lastVersion == currentAppVersion {
            return false
        }

        // 3. Respect cooldown if previously dismissed with "Maybe Later"
        if let declined = declinedDate, Date().timeIntervalSince(declined) < cooldownInterval {
            return false
        }

        // 4. Require minimum milestone engagement (routines or sessions)
        let hasEnoughRoutines = routinesCompletedCount >= minRoutinesForPrompt
        let hasEnoughSessions = sessionsCompletedCount >= minSessionsForPrompt

        return hasEnoughRoutines || hasEnoughSessions
    }

    // MARK: — Actions

    /// Record that the prompt was displayed.
    func recordPromptShown(trigger: String) {
        lastVersionPrompted = currentAppVersion
        AnalyticsService.shared.log(.ratingPromptShown(trigger: trigger))
        logger.info("App rating prompt shown (trigger: \(trigger))")
    }

    /// Open direct Mac App Store review URL.
    func rateOnAppStore(source: String = "prompt") {
        hasRated = true
        AnalyticsService.shared.log(.ratingAppStoreOpened(source: source))
        logger.info("Opening Mac App Store review (source: \(source))")

        // Try direct Mac App Store URL scheme first, fallback to https URL
        let appStoreSchemeURL = URL(string: "macappstore://apps.apple.com/app/id\(appStoreID)?action=write-review")
        let httpsURL          = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")

        if let schemeURL = appStoreSchemeURL, NSWorkspace.shared.open(schemeURL) {
            return
        }

        if let webURL = httpsURL {
            NSWorkspace.shared.open(webURL)
        }
    }

    /// Open default email client with support feedback template.
    func openFeedbackEmail(source: String = "prompt", starRating: Int? = nil) {
        AnalyticsService.shared.log(.ratingFeedbackOpened(source: source))
        logger.info("Opening feedback email (source: \(source))")

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let subject = "DeskReset Feedback (v\(appVersion))"
        let ratingInfo = starRating.map { "User Rating: \($0)/5 stars\n" } ?? ""
        let body = """
        Hi Suryakant,

        Here is my feedback on DeskReset:

        [Please share your feedback, bug report, or feature suggestion here]

        ---
        \(ratingInfo)App Version: \(appVersion) (\(buildNumber))
        macOS Version: \(osVersion)
        """

        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailURL = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)")
        else {
            return
        }

        NSWorkspace.shared.open(mailURL)
    }

    /// Handle dismissal of the rating prompt.
    func dismissPrompt(remindLater: Bool, action: String = "dismissed") {
        if remindLater {
            declinedDate = Date()
        } else {
            // "Never" or dismissed permanently
            hasRated = true
        }
        AnalyticsService.shared.log(.ratingPromptDismissed(action: action))
        logger.info("Rating prompt dismissed (remindLater: \(remindLater), action: \(action))")
    }

    // MARK: — Testing / Debug Helpers

    #if DEBUG
    func resetRatingState() {
        hasRated = false
        declinedDate = nil
        lastVersionPrompted = nil
        routinesCompletedCount = 0
        sessionsCompletedCount = 0
        logger.debug("Rating state successfully reset.")
    }

    func forceEligibleForTesting() {
        hasRated = false
        declinedDate = nil
        lastVersionPrompted = nil
        routinesCompletedCount = 10
        sessionsCompletedCount = 10
    }
    #endif
}
