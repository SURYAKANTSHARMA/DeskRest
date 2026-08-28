//
//  PostureService.swift
//  DeskReset
//
//  Camera + Vision framework posture detection service.
//  Subscribes to CameraService AsyncStream frames, performs body pose detection,
//  evaluates posture metrics against calibrated PostureBaseline, and publishes live state.
//

import Foundation
import Observation
import OSLog
import CoreMedia
import SwiftData

@Observable
@MainActor
final class PostureService: PostureServiceProtocol {

    // MARK: - Published State
    var isMonitoring: Bool                  = false
    var postureScore: Int                   = 100
    var currentSnapshot: PostureSnapshot?   = nil
    var currentAssessment: PostureAssessment? = nil
    var baseline: PostureBaseline           = .uncalibrated
    var monitoringInterval: TimeInterval    = 90 {
        didSet {
            if isMonitoring && oldValue != monitoringInterval {
                Logger.services.info("PostureService monitoring interval changed from \(oldValue)s to \(self.monitoringInterval)s. Restarting task.")
                // Restart monitoring loop immediately to adopt new interval
                startMonitoring()
            }
        }
    }
    var nextCheckTime: Date?                = nil
    var lastRunStatus: LastRunStatus        = .noScanYet

    var statusDescription: String {
        guard isMonitoring else { return "Monitoring stopped" }
        guard let assessment = currentAssessment else {
            return "Looking for body pose..."
        }
        if assessment.issues.isEmpty {
            return "Great posture!"
        }
        return assessment.summaryText
    }

    // MARK: - Private Dependencies & Tasks
    var modelContext: ModelContext?
    private var cameraService: (any CameraServiceProtocol)?
    private let visionAnalyzer  = VisionPoseAnalyzer()
    private let postureAnalyzer = PostureAnalyzer()
    private var frameTask: Task<Void, Never>?
    private var lastLogTime: Date = .distantPast

    // MARK: - Init
    init(
        cameraService: (any CameraServiceProtocol)? = nil,
        baseline: PostureBaseline = .uncalibrated
    ) {
        self.cameraService = cameraService
        self.baseline      = baseline
        Logger.services.info("PostureService initialized")
    }

    // MARK: - Baseline

    func updateBaseline(_ baseline: PostureBaseline) {
        self.baseline = baseline
        Logger.services.info("PostureService: baseline updated — isCalibrated=\(baseline.isCalibrated)")
    }

    // MARK: - Actions

    func startMonitoring() {
        guard let cameraService else {
            Logger.services.error("PostureService: Cannot start monitoring — CameraService missing")
            return
        }

        isMonitoring = true
        Logger.services.info("PostureService: startMonitoring()")

        frameTask?.cancel()
        frameTask = Task { @MainActor [weak self] in
            guard let self else { return }

            _ = await cameraService.requestPermission()

            while self.isMonitoring && !Task.isCancelled {
                // Reset EMA smoothing so the new 3-frame burst isn't skewed by posture from 90 seconds ago!
                self.postureAnalyzer.resetSmoothing()
                
                do {
                    try await cameraService.start()
                    
                    let startTime = Date()
                    var validFramesCount = 0
                    var latestResult: (PostureSnapshot, PostureAssessment)? = nil

                    let stream = cameraService.frameStream()
                    for await sampleBuffer in stream {
                        guard !Task.isCancelled, self.isMonitoring else { break }

                        if Date().timeIntervalSince(startTime) >= 3.0 {
                            break // 3-second hardware timeout
                        }

                        if let snapshot = self.visionAnalyzer.analyze(sampleBuffer: sampleBuffer) {
                            let assessment = self.postureAnalyzer.analyze(snapshot: snapshot, baseline: self.baseline)
                            validFramesCount += 1
                            latestResult = (snapshot, assessment)
                            if validFramesCount >= 3 {
                                break // Got 3 valid frames, done
                            }
                        }
                    }

                    if let (snapshot, assessment) = latestResult, validFramesCount >= 3 {
                        self.currentSnapshot   = snapshot
                        self.currentAssessment = assessment
                        self.postureScore      = assessment.score
                        self.lastRunStatus     = .success

                        let log = PostureLog(score: assessment.score, issuesSummary: assessment.summaryText)
                        self.modelContext?.insert(log)
                        try? self.modelContext?.save()

                        let topIssue = assessment.issues.first?.type.rawValue
                        let label = assessment.score >= 80 ? "Good" : (assessment.score >= 60 ? "Fair" : "Poor")
                        AnalyticsService.shared.log(.postureScanCompleted(
                            score: assessment.score,
                            scoreLabel: label,
                            topIssue: topIssue
                        ))
                        AnalyticsService.shared.setCrashlyticsKey("last_score", value: "\(assessment.score)")
                    } else {
                        Logger.services.info("Posture scan timed out (3.0s) — user away from desk or camera stuck.")
                        self.currentSnapshot   = nil
                        self.currentAssessment = nil
                        self.postureScore      = 0
                        self.lastRunStatus     = .personNotDetected

                        let log = PostureLog(score: 0, issuesSummary: "Away")
                        self.modelContext?.insert(log)
                        try? self.modelContext?.save()

                        AnalyticsService.shared.log(.postureScanFailed(reason: "person_not_detected_away"))
                    }

                    cameraService.stop()
                    self.nextCheckTime = Date.now.addingTimeInterval(self.monitoringInterval)

                    // Sleep until next interval
                    try await Task.sleep(nanoseconds: UInt64(self.monitoringInterval * 1_000_000_000))

                } catch {
                    Logger.services.error("PostureService monitoring polling loop error: \(error)")
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // retry in 5s on error
                }
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        frameTask?.cancel()
        frameTask = nil
        currentSnapshot = nil
        currentAssessment = nil
        postureScore = 100
        nextCheckTime = nil
        lastRunStatus = .noScanYet
        cameraService?.stop()
        Logger.services.info("PostureService: stopMonitoring()")
    }
}
