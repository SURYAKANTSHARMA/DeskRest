//
//  ErgonomicRecoveryRoutine.swift
//  DeskReset
//
//  Strongly typed structured output model for ergonomic recovery routines.
//  Strictly ergonomic workplace advice — NEVER medical advice.
//

import Foundation

// MARK: — ErgonomicExercise

public struct ErgonomicExercise: Sendable, Codable, Equatable, Identifiable {
    public var id: String { title }

    /// Title of the ergonomic exercise
    public let title: String
    /// Step-by-step movement instructions
    public let instructions: String
    /// Repetitions and hold time (e.g. "5 reps, 5-second hold")
    public let repetitions: String
    /// Target muscle group / area (e.g. "Deep Neck Flexors", "Rhomboids")
    public let targetMuscle: String
    /// Estimated duration (e.g. "45s")
    public let duration: String

    public init(
        title: String,
        instructions: String,
        repetitions: String,
        targetMuscle: String,
        duration: String
    ) {
        self.title = title
        self.instructions = instructions
        self.repetitions = repetitions
        self.targetMuscle = targetMuscle
        self.duration = duration
    }
}

// MARK: — ErgonomicRecoveryRoutine

public struct ErgonomicRecoveryRoutine: Sendable, Codable, Equatable, Identifiable {
    public var id: String { "\(detectedIssue)-\(timestamp.timeIntervalSince1970)" }

    public let timestamp: Date
    /// The detected posture issue triggering the routine
    public let detectedIssue: String
    /// Ergonomic explanation of why posture drift occurred
    public let explanation: String
    /// Structured list of ergonomic exercises
    public let exercises: [ErgonomicExercise]
    /// Total recommended routine duration (e.g. "2 minutes")
    public let totalDuration: String
    /// Workplace safety & comfort notes
    public let safetyNotes: [String]
    /// Strict non-medical guardrail disclaimer
    public let disclaimer: String

    public init(
        timestamp: Date = Date(),
        detectedIssue: String,
        explanation: String,
        exercises: [ErgonomicExercise],
        totalDuration: String,
        safetyNotes: [String],
        disclaimer: String = "DeskReset provides workplace ergonomic guidance. This is not medical advice, diagnosis, or treatment."
    ) {
        self.timestamp = timestamp
        self.detectedIssue = detectedIssue
        self.explanation = explanation
        self.exercises = exercises
        self.totalDuration = totalDuration
        self.safetyNotes = safetyNotes
        self.disclaimer = disclaimer
    }
}
