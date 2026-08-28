//
//  AICoachGuidance.swift
//  DeskReset
//
//  Data-driven AI coaching guidance model synthesizing historical posture logs,
//  ergonomic workspace fixes, micro-exercises, and habit recommendations.
//

import Foundation

public struct AICoachGuidance: Sendable, Equatable {

    public enum InsightType: String, Sendable, Codable {
        case correction      = "Correction Needed"
        case fatiguePattern  = "Fatigue Trend"
        case improving       = "Improving"
        case optimal         = "Optimal Alignment"
        case setupGuide      = "Workstation Setup"
    }

    public let type: InsightType
    public let headline: String
    public let badgeText: String
    public let badgeIcon: String
    public let dataMetricText: String        // e.g. "Flagged in 42% of today's checks"
    public let diagnosticExplanation: String // Root-cause explanation synthesized from previous data
    
    // Ergonomic Desk/Hardware Fix
    public let ergonomicFixTitle: String     // e.g. "Monitor & Eyeline Alignment"
    public let ergonomicFixDetails: String   // e.g. "Raise monitor 2–3 inches so top 1/3 is at eye level..."
    public let targetArea: String            // e.g. "Cervical Spine (Neck)"

    // Quick Micro-Exercise
    public let microExerciseTitle: String    // e.g. "Chin Retraction & Tuck"
    public let microExerciseDuration: String // e.g. "45s • 5 reps"
    public let microExerciseTarget: String   // e.g. "Deep Neck Flexors"
    public let microExerciseInstruction: String

    // Habit & Workday Wisdom
    public let habitTip: String              // e.g. "Afternoon slump detected: Take a 30s reset every 45m"

    // Associated recovery routine for interactive execution
    public let routine: ErgonomicRecoveryRoutine

    public init(
        type: InsightType,
        headline: String,
        badgeText: String,
        badgeIcon: String,
        dataMetricText: String,
        diagnosticExplanation: String,
        ergonomicFixTitle: String,
        ergonomicFixDetails: String,
        targetArea: String,
        microExerciseTitle: String,
        microExerciseDuration: String,
        microExerciseTarget: String,
        microExerciseInstruction: String,
        habitTip: String,
        routine: ErgonomicRecoveryRoutine
    ) {
        self.type = type
        self.headline = headline
        self.badgeText = badgeText
        self.badgeIcon = badgeIcon
        self.dataMetricText = dataMetricText
        self.diagnosticExplanation = diagnosticExplanation
        self.ergonomicFixTitle = ergonomicFixTitle
        self.ergonomicFixDetails = ergonomicFixDetails
        self.targetArea = targetArea
        self.microExerciseTitle = microExerciseTitle
        self.microExerciseDuration = microExerciseDuration
        self.microExerciseTarget = microExerciseTarget
        self.microExerciseInstruction = microExerciseInstruction
        self.habitTip = habitTip
        self.routine = routine
    }
}
