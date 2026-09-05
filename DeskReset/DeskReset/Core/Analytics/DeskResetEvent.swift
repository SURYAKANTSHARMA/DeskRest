//
//  DeskResetEvent.swift
//  DeskReset
//
//  Type-safe GA4 event taxonomy for DeskReset.
//  All names follow GA4 conventions: snake_case, max 40 chars.
//

import Foundation

// MARK: — Event Definitions

enum DeskResetEvent {

    // ── Onboarding Funnel ────────────────────────────────────────────────
    case onboardingStarted
    case onboardingStepViewed(stepIndex: Int, stepName: String)
    case onboardingCompleted
    case onboardingSkipped(atStep: Int)

    // ── Calibration Funnel ───────────────────────────────────────────────
    case calibrationStarted(source: String)   // "dashboard" | "banner" | "onboarding"
    case calibrationCompleted(durationSeconds: Int)
    case calibrationCancelled
    case calibrationFailed(reason: String, samplesCollected: Int)

    // ── Monitoring Session ───────────────────────────────────────────────
    case monitoringStarted(isCalibrated: Bool, source: String = "dashboard")
    case monitoringStopped(durationSeconds: Int, scanCount: Int, source: String = "dashboard")

    // ── Posture Scan ─────────────────────────────────────────────────────
    case postureScanCompleted(score: Int, scoreLabel: String, topIssue: String?)
    case postureScanFailed(reason: String)    // "timeout_away" | "camera_error" | "pose_not_detected"

    // ── Navigation & Screens ─────────────────────────────────────────────
    case screenViewed(screenName: String)   // "overview" | "history" | "settings"
    case cameraDebugOpened

    // ── Engagement & Habits ──────────────────────────────────────────────
    case breakTaken(durationMinutes: Int)
    case breakSkipped(durationMinutes: Int)
    case dailyStreakMilestone(days: Int)
    case legalDocumentViewed(documentName: String)
    case scanIntervalChanged(intervalSeconds: Int)
    case quickActionTriggered(source: String, action: String) // e.g. "menu_bar", "start_monitoring"
    case settingsUpdated(settingName: String, value: String)

    // ── App Rating & Feedback ───────────────────────────────────────────
    case ratingPromptShown(trigger: String)
    case ratingSentimentSelected(sentiment: String, rating: Int)
    case ratingAppStoreOpened(source: String)
    case ratingFeedbackOpened(source: String)
    case ratingPromptDismissed(action: String)

    // ── Failures & Permissions ───────────────────────────────────────────
    case cameraPermissionDenied(status: String) // "denied" | "restricted"
    case cameraError(error: String)
    case notificationPermissionDenied
    case dataStoreError(operation: String, error: String)
    case appError(domain: String, code: Int, message: String)
}

// MARK: — GA4 Serialisation

extension DeskResetEvent {

    /// GA4 event name (snake_case, max 40 chars).
    var name: String {
        switch self {
        case .onboardingStarted:          return "onboarding_started"
        case .onboardingStepViewed:       return "onboarding_step_viewed"
        case .onboardingCompleted:        return "onboarding_completed"
        case .onboardingSkipped:          return "onboarding_skipped"
        case .calibrationStarted:         return "calibration_started"
        case .calibrationCompleted:       return "calibration_completed"
        case .calibrationCancelled:       return "calibration_cancelled"
        case .calibrationFailed:          return "calibration_failed"
        case .monitoringStarted:          return "monitoring_started"
        case .monitoringStopped:          return "monitoring_stopped"
        case .postureScanCompleted:       return "posture_scan_completed"
        case .postureScanFailed:          return "posture_scan_failed"
        case .screenViewed:               return "screen_view"
        case .cameraDebugOpened:          return "camera_debug_opened"
        case .breakTaken:                 return "break_taken"
        case .breakSkipped:               return "break_skipped"
        case .dailyStreakMilestone:       return "streak_milestone_achieved"
        case .legalDocumentViewed:        return "legal_document_viewed"
        case .scanIntervalChanged:        return "scan_interval_changed"
        case .quickActionTriggered:       return "quick_action_triggered"
        case .settingsUpdated:            return "settings_updated"
        case .ratingPromptShown:          return "rating_prompt_shown"
        case .ratingSentimentSelected:    return "rating_sentiment_selected"
        case .ratingAppStoreOpened:       return "rating_app_store_opened"
        case .ratingFeedbackOpened:       return "rating_feedback_opened"
        case .ratingPromptDismissed:      return "rating_prompt_dismissed"
        case .cameraPermissionDenied:     return "camera_permission_denied"
        case .cameraError:                return "camera_error"
        case .notificationPermissionDenied: return "notification_permission_denied"
        case .dataStoreError:             return "data_store_error"
        case .appError:                   return "app_error"
        }
    }

    /// GA4 event parameters (snake_case keys, max 25 params).
    var parameters: [String: Any] {
        switch self {
        case .onboardingStarted:
            return [:]
        case .onboardingStepViewed(let idx, let name):
            return ["step_index": idx, "step_name": name]
        case .onboardingCompleted:
            return ["total_steps": 4]
        case .onboardingSkipped(let atStep):
            return ["at_step": atStep]
        case .calibrationStarted(let source):
            return ["source": source]
        case .calibrationCompleted(let duration):
            return ["duration_seconds": duration]
        case .calibrationCancelled:
            return [:]
        case .calibrationFailed(let reason, let samples):
            return ["failure_reason": reason, "samples_collected": samples]
        case .monitoringStarted(let isCalibrated, let source):
            return ["is_calibrated": isCalibrated ? "true" : "false", "source": source]
        case .monitoringStopped(let duration, let scanCount, let source):
            return ["duration_seconds": duration, "scan_count": scanCount, "source": source]
        case .postureScanCompleted(let score, let label, let issue):
            var p: [String: Any] = ["score": score, "score_label": label]
            if let issue { p["top_issue"] = issue }
            return p
        case .postureScanFailed(let reason):
            return ["failure_reason": reason]
        case .screenViewed(let screen):
            return ["screen_name": screen, "firebase_screen_name": screen]
        case .cameraDebugOpened:
            return [:]
        case .breakTaken(let minutes):
            return ["duration_minutes": minutes]
        case .breakSkipped(let minutes):
            return ["duration_minutes": minutes]
        case .dailyStreakMilestone(let days):
            return ["streak_days": days]
        case .legalDocumentViewed(let doc):
            return ["document_name": doc]
        case .scanIntervalChanged(let seconds):
            return ["interval_seconds": seconds]
        case .quickActionTriggered(let source, let action):
            return ["action_source": source, "action_name": action]
        case .settingsUpdated(let setting, let value):
            return ["setting_name": setting, "setting_value": value]
        case .ratingPromptShown(let trigger):
            return ["trigger": trigger]
        case .ratingSentimentSelected(let sentiment, let rating):
            return ["sentiment": sentiment, "star_rating": rating]
        case .ratingAppStoreOpened(let source):
            return ["source": source]
        case .ratingFeedbackOpened(let source):
            return ["source": source]
        case .ratingPromptDismissed(let action):
            return ["action": action]
        case .cameraPermissionDenied(let status):
            return ["permission_status": status]
        case .cameraError(let error):
            return ["error_message": error]
        case .notificationPermissionDenied:
            return [:]
        case .dataStoreError(let op, let err):
            return ["operation": op, "error_message": err]
        case .appError(let domain, let code, let message):
            return ["error_domain": domain, "error_code": code, "error_message": message]
        }
    }
}
