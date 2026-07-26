//
//  PostureAnalyzer.swift
//  DeskReset
//
//  Pure geometric posture analysis engine.
//  Evaluates body pose metrics (forward head, rounded shoulders, shoulder imbalance, torso lean)
//  by comparing against the user's calibrated neutral baseline, smooths metrics via EMA,
//  and filters out noise.
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

        guard let head = snapshot.head,
              let neck = snapshot.neck,
              let lShoulder = snapshot.leftShoulder,
              let rShoulder = snapshot.rightShoulder else {
            return PostureAssessment()
        }

        // 2. Compute Raw Instantaneous Metrics

        // A. Forward Head Offset: horizontal distance between Head and Neck
        let rawHeadOffset = abs(Double(head.point.x - neck.point.x))

        // B. Shoulder Imbalance: angle of line connecting left & right shoulder (in degrees)
        let dxShoulders = Double(rShoulder.point.x - lShoulder.point.x)
        let dyShoulders = Double(rShoulder.point.y - lShoulder.point.y)
        let rawShoulderTilt = atan2(dyShoulders, dxShoulders) * (180.0 / .pi)

        // C. Torso Lean: lateral tilt angle of neck -> torso line relative to vertical
        let torsoPoint = snapshot.torso?.point ?? CGPoint(
            x: (lShoulder.point.x + rShoulder.point.x) / 2.0,
            y: (lShoulder.point.y + rShoulder.point.y) / 2.0 - 0.2
        )
        let dxTorso = Double(torsoPoint.x - neck.point.x)
        let dyTorso = Double(neck.point.y - torsoPoint.y) // Y increases upward in Vision
        let rawTorsoLean = atan2(dxTorso, max(dyTorso, 0.001)) * (180.0 / .pi)

        // D. Shoulder Width Ratio: shoulder width relative to neck-to-torso height
        let shoulderWidth = hypot(dxShoulders, dyShoulders)
        let torsoHeight   = max(hypot(dxTorso, dyTorso), 0.05)
        let rawWidthRatio = shoulderWidth / torsoHeight

        // 3. Smooth Metrics (Exponential Moving Average)

        if !hasInitializedEMA {
            smoothedForwardHeadOffset  = rawHeadOffset
            smoothedShoulderTilt       = rawShoulderTilt
            smoothedTorsoLean          = rawTorsoLean
            smoothedShoulderWidthRatio = rawWidthRatio
            hasInitializedEMA = true
        } else {
            smoothedForwardHeadOffset  = (alpha * rawHeadOffset) + ((1.0 - alpha) * smoothedForwardHeadOffset)
            smoothedShoulderTilt       = (alpha * rawShoulderTilt) + ((1.0 - alpha) * smoothedShoulderTilt)
            smoothedTorsoLean          = (alpha * rawTorsoLean) + ((1.0 - alpha) * smoothedTorsoLean)
            smoothedShoulderWidthRatio = (alpha * rawWidthRatio) + ((1.0 - alpha) * smoothedShoulderWidthRatio)
        }

        // 4. Evaluate Posture Issues Relative to Calibrated Baseline

        var issues: [PostureIssue] = []

        // Issue 1: Forward Head Posture (relative to calibrated baseline head offset)
        let targetHeadOffset = baseline.isCalibrated ? baseline.headOffset : 0.0
        let headOffsetDelta  = abs(smoothedForwardHeadOffset - targetHeadOffset)

        if headOffsetDelta > Thresholds.forwardHeadMild {
            let sev: PostureIssue.Severity =
                headOffsetDelta > Thresholds.forwardHeadSevere ? .severe :
                (headOffsetDelta > Thresholds.forwardHeadModerate ? .moderate : .mild)

            issues.append(PostureIssue(
                type: .forwardHead,
                severity: sev,
                description: "Head is forward from your calibrated baseline."
            ))
        }

        // Issue 2: Shoulder Imbalance (relative to calibrated baseline shoulder tilt)
        let targetShoulderTilt = baseline.isCalibrated ? baseline.shoulderTilt : 0.0
        let shoulderTiltDelta  = abs(smoothedShoulderTilt - targetShoulderTilt)

        if shoulderTiltDelta > Thresholds.shoulderTiltMild {
            let sev: PostureIssue.Severity =
                shoulderTiltDelta > Thresholds.shoulderTiltSevere ? .severe :
                (shoulderTiltDelta > Thresholds.shoulderTiltModerate ? .moderate : .mild)

            let side = (smoothedShoulderTilt - targetShoulderTilt) > 0 ? "Right" : "Left"
            issues.append(PostureIssue(
                type: .shoulderImbalance,
                severity: sev,
                description: "\(side) shoulder is elevated from baseline."
            ))
        }

        // Issue 3: Torso Lean (relative to calibrated baseline torso lean)
        let targetTorsoLean = baseline.isCalibrated ? baseline.torsoLean : 0.0
        let torsoLeanDelta  = abs(smoothedTorsoLean - targetTorsoLean)

        if torsoLeanDelta > Thresholds.torsoLeanMild {
            let sev: PostureIssue.Severity =
                torsoLeanDelta > Thresholds.torsoLeanSevere ? .severe :
                (torsoLeanDelta > Thresholds.torsoLeanModerate ? .moderate : .mild)

            let dir = (smoothedTorsoLean - targetTorsoLean) > 0 ? "right" : "left"
            issues.append(PostureIssue(
                type: .torsoLean,
                severity: sev,
                description: "Torso is leaning \(dir) from baseline."
            ))
        }

        // Issue 4: Rounded Shoulders (relative to calibrated baseline shoulder width ratio)
        let targetWidthRatio = baseline.isCalibrated ? baseline.shoulderWidthRatio : 1.0
        let relativeWidthCompression = smoothedShoulderWidthRatio / max(targetWidthRatio, 0.1)

        if relativeWidthCompression < Thresholds.roundedShouldersRatioThreshold {
            issues.append(PostureIssue(
                type: .roundedShoulders,
                severity: .moderate,
                description: "Shoulders are rounded forward from baseline."
            ))
        }

        // 5. Compute Posture Score (0 - 100)

        var score = 100
        for issue in issues {
            switch issue.severity {
            case .mild:     score -= 10
            case .moderate: score -= 20
            case .severe:   score -= 30
            }
        }
        score = max(0, min(100, score))

        // Determine Overall Quality
        let quality: PostureQuality
        switch score {
        case 85...100: quality = .good
        case 65..<85:  quality = .fair
        default:       quality = .poor
        }

        return PostureAssessment(
            timestamp: Date(),
            quality: quality,
            score: score,
            issues: issues,
            forwardHeadOffset: smoothedForwardHeadOffset,
            shoulderImbalanceDegrees: smoothedShoulderTilt,
            torsoLeanDegrees: smoothedTorsoLean,
            shoulderWidthRatio: smoothedShoulderWidthRatio
        )
    }

    // MARK: — Noise Filter

    private func isSnapshotValid(_ snapshot: PostureSnapshot) -> Bool {
        guard snapshot.isDetected else { return false }

        let minConf: Float = 0.20
        let reqJoints = [snapshot.head, snapshot.neck, snapshot.leftShoulder, snapshot.rightShoulder]

        let validCount = reqJoints.compactMap { $0 }.filter { $0.confidence >= minConf }.count
        return validCount >= 3
    }
}
