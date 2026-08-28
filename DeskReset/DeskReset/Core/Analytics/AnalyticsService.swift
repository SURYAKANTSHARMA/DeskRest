//
//  AnalyticsService.swift
//  DeskReset
//
//  Thin wrapper around Firebase Analytics + Crashlytics.
//  Uses #if canImport guards so the app compiles and runs before/after
//  the Firebase SPM package is linked.
//

import Foundation
import OSLog

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// MARK: — Analytics Service

/// Singleton analytics service. Thread-safe — all Firebase calls are dispatched
/// to the main actor via the call sites (Views / ViewModels).
final class AnalyticsService {

    static let shared = AnalyticsService()

    private let log = Logger(subsystem: "com.deskreset.app", category: "Analytics")

    // Tracks whether Firebase SDK is present at runtime.
    var isFirebaseAvailable: Bool {
        #if canImport(FirebaseAnalytics)
        return true
        #else
        return false
        #endif
    }

    private init() {}

    // MARK: — Log Event

    /// Log a typed DeskReset event to GA4 and as a Crashlytics breadcrumb.
    func log(_ event: DeskResetEvent) {
        let name   = event.name
        let params = event.parameters

        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: params.isEmpty ? nil : params)
        #endif

        #if canImport(FirebaseCrashlytics)
        let paramString = params.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        Crashlytics.crashlytics().log("Event: \(name) (\(paramString))")
        #endif

        // Always log to OSLog for DebugView and local testing
        log.debug("📊 [\(name)] \(params.isEmpty ? "" : "\(params)")")
    }

    // MARK: — Breadcrumbs

    /// Log a developer breadcrumb to Crashlytics to trace user steps leading up to an issue.
    func logBreadcrumb(_ message: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #endif
        log.debug("🍞 [Breadcrumb] \(message)")
    }

    // MARK: — User Properties

    /// Set a GA4 user property that persists across sessions.
    /// Use for segmentation: is_calibrated, monitoring_interval_bucket, etc.
    func setUserProperty(_ value: String?, forName name: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
        log.debug("👤 user_property [\(name)] = \(value ?? "nil")")
    }

    // MARK: — Crashlytics — Non-fatal error

    /// Record a non-fatal error to Crashlytics with descriptive context and GA4 event.
    func recordError(_ error: Error, context: [String: String] = [:]) {
        #if canImport(FirebaseCrashlytics)
        let crashlytics = Crashlytics.crashlytics()
        for (key, value) in context {
            crashlytics.setCustomValue(value, forKey: key)
        }
        crashlytics.record(error: error)
        #endif

        let nsError = error as NSError
        log(.appError(domain: nsError.domain, code: nsError.code, message: error.localizedDescription))
        log.error("🔥 non_fatal_error: \(error.localizedDescription) context=\(context)")
    }

    // MARK: — Crashlytics — Custom Keys (session context)

    /// Attach a key/value to every future crash report for better context.
    func setCrashlyticsKey(_ key: String, value: String) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        #endif
    }

    /// Set an anonymous user identifier for Crashlytics grouping.
    /// Never pass real PII — use a UUID stored in UserDefaults.
    func setAnonymousUserID() {
        let key = "dr_analytics_user_id"
        let existingID = UserDefaults.standard.string(forKey: key)
        let userID = existingID ?? UUID().uuidString
        if existingID == nil {
            UserDefaults.standard.set(userID, forKey: key)
        }
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().setUserID(userID)
        #endif
        #if canImport(FirebaseAnalytics)
        Analytics.setUserID(userID)
        #endif
        log.debug("🆔 anonymous_user_id set: \(userID.prefix(8))...")
    }

    // MARK: — DebugView Helper

    /// Enable Analytics DebugView for this device.
    /// Add -FIRDebugEnabled to the scheme's launch arguments to activate.
    func configureDebugView() {
        #if DEBUG && canImport(FirebaseAnalytics)
        log.info("🔍 Firebase DebugView active. Open Firebase Console → Analytics → DebugView")
        #endif
    }
}
