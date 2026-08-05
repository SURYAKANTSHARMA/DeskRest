//
//  PostureAssessment.swift
//  DeskReset
//
//  Represents the calculated posture health assessment derived from body pose geometry.
//

import Foundation

// MARK: — PostureQuality

public enum PostureQuality: String, Sendable, Codable, Equatable {
    case good     = "Good"
    case fair     = "Fair"
    case poor     = "Needs Adjustment"
    case unknown  = "Detecting..."

    var icon: String {
        switch self {
        case .good:    return "checkmark.seal.fill"
        case .fair:    return "exclamationmark.triangle.fill"
        case .poor:    return "xmark.octagon.fill"
        case .unknown: return "figure.stand"
        }
    }
}

// MARK: — PostureIssue

public struct PostureIssue: Sendable, Equatable, Identifiable {
    public var id: String { type.rawValue }
    public let type: IssueType
    public let severity: Severity
    public let description: String

    public enum IssueType: String, Sendable, CaseIterable {
        case forwardHead      = "Forward Head Posture"
        case roundedShoulders  = "Rounded Shoulders"
        case shoulderImbalance = "Uneven Shoulders"
        case torsoLean        = "Torso Lean"

        public var icon: String {
            switch self {
            case .forwardHead:      return "person.and.arrow.left.and.arrow.right"
            case .roundedShoulders:  return "arrow.curve.right.left"
            case .shoulderImbalance: return "arrow.up.and.down"
            case .torsoLean:        return "arrow.triangle.2.circlepath"
            }
        }
    }

    public enum Severity: String, Sendable {
        case mild     = "Mild"
        case moderate = "Moderate"
        case severe   = "Severe"
    }

    public init(type: IssueType, severity: Severity, description: String) {
        self.type = type
        self.severity = severity
        self.description = description
    }
}

// MARK: — PostureAssessment

public struct PostureAssessment: Sendable, Equatable {
    public let timestamp: Date
    public let quality: PostureQuality
    public let score: Int // 0 → 100
    public let issues: [PostureIssue]

    // Raw smoothed geometric metrics
    public let forwardHeadOffset: Double        // normalized horizontal/vertical offset
    public let shoulderImbalanceDegrees: Double // tilt angle in degrees
    public let torsoLeanDegrees: Double        // lateral tilt angle in degrees
    public let shoulderWidthRatio: Double       // relative shoulder compression

    public var isGoodPosture: Bool { quality == .good }
    public var hasIssues: Bool { !issues.isEmpty }

    public var summaryText: String {
        if issues.isEmpty {
            return "Great posture! Keep it up."
        }
        let issueNames = issues.map { $0.type.rawValue }.joined(separator: ", ")
        return "Detected: \(issueNames)"
    }

    public init(
        timestamp: Date = Date(),
        quality: PostureQuality = .unknown,
        score: Int = 100,
        issues: [PostureIssue] = [],
        forwardHeadOffset: Double = 0,
        shoulderImbalanceDegrees: Double = 0,
        torsoLeanDegrees: Double = 0,
        shoulderWidthRatio: Double = 1.0
    ) {
        self.timestamp = timestamp
        self.quality = quality
        self.score = score
        self.issues = issues
        self.forwardHeadOffset = forwardHeadOffset
        self.shoulderImbalanceDegrees = shoulderImbalanceDegrees
        self.torsoLeanDegrees = torsoLeanDegrees
        self.shoulderWidthRatio = shoulderWidthRatio
    }
}
