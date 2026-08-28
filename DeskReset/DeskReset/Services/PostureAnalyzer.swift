//
//  PostureAnalyzer.swift
//  DeskReset
//
//  Pure-domain ergonomic posture analysis engine.
//  Evaluates joint coordinates against a PostureBaseline and identifies specific issues:
//  - Forward Head (tech neck)
//  - Shoulder Imbalance (one shoulder higher)
//  - Torso Lean (lateral tilt)
//  - Rounded Shoulders (inward shoulder rotation)
//
//  Calculates a continuous 0–100 ergonomic score.
//

import Foundation
import CoreGraphics
import OSLog

final class PostureAnalyzer: @unchecked Sendable {

    // MARK: — Metric History for Exponential Moving Average (EMA)
    private var smoothedForwardHeadOffset: Double  = 0.0
    private var smoothedShoulderTilt: Double      = 0.0
    private var smoothedTorsoLean: Double         = 0.0
    private var smoothedShoulderWidthRatio: Double = 1.0

    private var hasInitializedEMA: Bool = false
    private let alpha: Double = 0.25 // EMA smoothing factor (25% new, 75% history)

    // MARK: — Baseline Deviation Thresholds

    private enum Thresholds {
        // Deviation from calibrated head offset
        static let forwardHeadMild     = 0.035
        static let forwardHeadModerate = 0.060
        static let forwardHeadSevere   = 0.085

        // Deviation from calibrated shoulder tilt (degrees)
        static let shoulderTiltMild     = 3.0
        static let shoulderTiltModerate = 5.5
        static let shoulderTiltSevere   = 8.0

        // Deviation from calibrated torso lean (degrees)
        static let torsoLeanMild     = 3.5
        static let torsoLeanModerate = 6.0
        static let torsoLeanSevere   = 9.0

        // Ratio of current shoulder width vs baseline shoulder width
        static let roundedShouldersRatioThreshold = 0.88
    }

    init() {}

    func resetSmoothing() {
        hasInitializedEMA = false
    }

    // MARK: — Analyze Frame

    /// Analyzes a single PostureSnapshot against the user's calibrated PostureBaseline.
    func analyze(snapshot: PostureSnapshot, baseline: PostureBaseline = .uncalibrated) -> PostureAssessment {
        // 1. Noise Filter: verify required keypoints exist with sufficient confidence
        guard isSnapshotValid(snapshot) else {
            return PostureAssessment(
                timestamp: Date(),
                quality: .unknown,
                score: 100,
                issues: [],
                forwardHeadOffset: smoothedForwardHeadOffset,
                shoulderImbalanceDegrees: smoothedShoulderTilt,
                torsoLeanDegrees: smoothedTorsoLean,
                shoulderWidthRatio: smoothedShoulderWidthRatio
            )
        }

        guard let head      = snapshot.head,
              let neck      = snapshot.neck,
              let lShoulder = snapshot.leftShoulder,
              let rShoulder = snapshot.rightShoulder else {
            return PostureAssessment()
        }

        // 2. Anatomical Normalisation Vectors
        let dxShoulders = Double(rShoulder.point.x - lShoulder.point.x)
        let dyShoulders = Double(rShoulder.point.y - lShoulder.point.y)
        let currentShoulderWidth = hypot(dxShoulders, dyShoulders)

        let torsoBase = snapshot.torso?.point ?? CGPoint(
            x: (lShoulder.point.x + rShoulder.point.x) / 2.0,
            y: (lShoulder.point.y + rShoulder.point.y) / 2.0 - CGFloat(currentShoulderWidth * 1.5)
        )
        let midShoulders = CGPoint(
            x: (lShoulder.point.x + rShoulder.point.x) / 2.0,
            y: (lShoulder.point.y + rShoulder.point.y) / 2.0
        )
        let dxTorso = Double(midShoulders.x - torsoBase.x)
        let dyTorso = Double(midShoulders.y - torsoBase.y)
        let currentTorsoHeight = max(hypot(dxTorso, dyTorso), 0.05)

        // 3. Raw Metric Calculations
        let headDist = hypot(Double(head.point.x - neck.point.x), Double(head.point.y - neck.point.y))
        let rawHeadOffset = headDist / currentTorsoHeight

        let shoulderAngleRad = atan2(dyShoulders, dxShoulders)
        let rawShoulderTiltDegrees = abs(shoulderAngleRad * 180.0 / .pi)

        let torsoAngleRad = atan2(dxTorso, dyTorso)
        let rawTorsoLeanDegrees = abs(torsoAngleRad * 180.0 / .pi)

        let rawWidthRatio = currentShoulderWidth / currentTorsoHeight

        // 4. Temporal Smoothing (EMA)
        if !hasInitializedEMA {
            smoothedForwardHeadOffset  = rawHeadOffset
            smoothedShoulderTilt       = rawShoulderTiltDegrees
            smoothedTorsoLean          = rawTorsoLeanDegrees
            smoothedShoulderWidthRatio = rawWidthRatio
            hasInitializedEMA          = true
        } else {
            smoothedForwardHeadOffset  = alpha * rawHeadOffset           + (1.0 - alpha) * smoothedForwardHeadOffset
            smoothedShoulderTilt       = alpha * rawShoulderTiltDegrees  + (1.0 - alpha) * smoothedShoulderTilt
            smoothedTorsoLean          = alpha * rawTorsoLeanDegrees     + (1.0 - alpha) * smoothedTorsoLean
            smoothedShoulderWidthRatio = alpha * rawWidthRatio           + (1.0 - alpha) * smoothedShoulderWidthRatio
        }

        // 5. Evaluate Deviations against Baseline
        var issues: [PostureIssue] = []
        var totalPenalty: Double = 0.0

        // --- Issue 1: Forward Head ---
        let baselineHeadOffset = baseline.isCalibrated ? baseline.headOffset : 0.0
        let headDelta = smoothedForwardHeadOffset - baselineHeadOffset

        if headDelta > Thresholds.forwardHeadMild {
            let severity: PostureIssue.Severity
            let penalty: Double

            if headDelta > Thresholds.forwardHeadSevere {
                severity = .severe; penalty = 35.0
            } else if headDelta > Thresholds.forwardHeadModerate {
                severity = .moderate; penalty = 20.0
            } else {
                severity = .mild; penalty = 10.0
            }
            issues.append(PostureIssue(
                type: .forwardHead,
                severity: severity,
                description: "Head is positioned forward past your shoulders."
            ))
            totalPenalty += penalty
        }

        // --- Issue 2: Shoulder Imbalance ---
        let baselineShoulderTilt = baseline.isCalibrated ? baseline.shoulderTilt : 0.0
        let shoulderTiltDelta = abs(smoothedShoulderTilt - baselineShoulderTilt)

        if shoulderTiltDelta > Thresholds.shoulderTiltMild {
            let severity: PostureIssue.Severity
            let penalty: Double

            if shoulderTiltDelta > Thresholds.shoulderTiltSevere {
                severity = .severe; penalty = 30.0
            } else if shoulderTiltDelta > Thresholds.shoulderTiltModerate {
                severity = .moderate; penalty = 18.0
            } else {
                severity = .mild; penalty = 8.0
            }
            let highSide = smoothedShoulderTilt > 0 ? "right" : "left"
            issues.append(PostureIssue(
                type: .shoulderImbalance,
                severity: severity,
                description: "Your \(highSide) shoulder is raised higher than the other."
            ))
            totalPenalty += penalty
        }

        // --- Issue 3: Torso Lean ---
        let baselineTorsoLean = baseline.isCalibrated ? baseline.torsoLean : 0.0
        let torsoLeanDelta = abs(smoothedTorsoLean - baselineTorsoLean)

        if torsoLeanDelta > Thresholds.torsoLeanMild {
            let severity: PostureIssue.Severity
            let penalty: Double

            if torsoLeanDelta > Thresholds.torsoLeanSevere {
                severity = .severe; penalty = 30.0
            } else if torsoLeanDelta > Thresholds.torsoLeanModerate {
                severity = .moderate; penalty = 18.0
            } else {
                severity = .mild; penalty = 8.0
            }
            let leanSide = dyTorso > 0 ? "right" : "left"
            issues.append(PostureIssue(
                type: .torsoLean,
                severity: severity,
                description: "Leaning your upper body to the \(leanSide)."
            ))
            totalPenalty += penalty
        }

        // --- Issue 4: Rounded Shoulders ---
        if baseline.isCalibrated && baseline.shoulderWidthRatio > 0 {
            let ratio = smoothedShoulderWidthRatio / baseline.shoulderWidthRatio
            if ratio < Thresholds.roundedShouldersRatioThreshold {
                let severity: PostureIssue.Severity = ratio < 0.78 ? .severe : (ratio < 0.84 ? .moderate : .mild)
                let penalty: Double = ratio < 0.78 ? 25.0 : (ratio < 0.84 ? 15.0 : 8.0)
                issues.append(PostureIssue(
                    type: .roundedShoulders,
                    severity: severity,
                    description: "Shoulders are rolled forward and inward."
                ))
                totalPenalty += penalty
            }
        }

        // 6. Final Score Calculation
        let calculatedScore = max(0, min(100, Int(round(100.0 - totalPenalty))))

        let quality: PostureQuality
        switch calculatedScore {
        case 80...100: quality = .good
        case 60..<80:  quality = .fair
        default:       quality = .poor
        }

        return PostureAssessment(
            timestamp: Date(),
            quality: quality,
            score: calculatedScore,
            issues: issues,
            forwardHeadOffset: smoothedForwardHeadOffset,
            shoulderImbalanceDegrees: smoothedShoulderTilt,
            torsoLeanDegrees: smoothedTorsoLean,
            shoulderWidthRatio: smoothedShoulderWidthRatio
        )
    }

    // MARK: - Validation Helpers

    private func isSnapshotValid(_ snapshot: PostureSnapshot) -> Bool {
        guard snapshot.isDetected,
              let neck = snapshot.neck, neck.confidence >= 0.3,
              let lShoulder = snapshot.leftShoulder, lShoulder.confidence >= 0.3,
              let rShoulder = snapshot.rightShoulder, rShoulder.confidence >= 0.3 else {
            return false
        }
        return true
    }
}
