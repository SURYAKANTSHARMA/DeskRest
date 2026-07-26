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
final class PostureService: PostureServiceProtocol {

    // MARK: - Published State
    var isMonitoring: Bool                  = false
    var postureScore: Int                   = 100
    var currentSnapshot: PostureSnapshot?   = nil
    var currentAssessment: PostureAssessment? = nil
    var baseline: PostureBaseline           = .uncalibrated

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
    }

    func setCameraService(_ cameraService: any CameraServiceProtocol) {
        self.cameraService = cameraService
    }

    func updateBaseline(_ baseline: PostureBaseline) {
        self.baseline = baseline
        postureAnalyzer.resetSmoothing()
        Logger.services.info("PostureService baseline updated — isCalibrated=\(baseline.isCalibrated)")
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
        frameTask = Task { [weak self] in
            guard let self else { return }

            // Ensure camera is authorized & running
            if !cameraService.isRunning {
                _ = await cameraService.requestPermission()
                try? await cameraService.start()
            }

            let stream = cameraService.frameStream()
            for await sampleBuffer in stream {
                guard !Task.isCancelled else { break }

                // 1. Detect Vision body pose
                let snapshot = self.visionAnalyzer.analyze(sampleBuffer: sampleBuffer)

                // 2. Perform posture analysis & smoothing using calibrated baseline
                let assessment = snapshot.map { self.postureAnalyzer.analyze(snapshot: $0, baseline: self.baseline) }

                await MainActor.run {
                    self.currentSnapshot   = snapshot
                    self.currentAssessment = assessment
                    if let score = assessment?.score {
                        self.postureScore  = score
                        if Date.now.timeIntervalSince(self.lastLogTime) >= 60 {
                            self.lastLogTime = .now
                            let log = PostureLog(score: score)
                            self.modelContext?.insert(log)
                            try? self.modelContext?.save()
                        }
                    }
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
        cameraService?.stop()
        Logger.services.info("PostureService: stopMonitoring()")
    }

    deinit {
        frameTask?.cancel()
    }
}
