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
    var monitoringInterval: TimeInterval    = 90
    var nextCheckTime: Date?                = nil

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

            _ = await cameraService.requestPermission()

            while self.isMonitoring && !Task.isCancelled {
                do {
                    try await cameraService.start()
                    // Enforce a strict 3.0 second timeout using a TaskGroup race
                    do {
                        try await withThrowingTaskGroup(of: Void.self) { group in
                            // Task 1: Frame processing stream
                            group.addTask {
                                let stream = cameraService.frameStream()
                                var validFramesCount = 0
                                
                                for await sampleBuffer in stream {
                                    guard !Task.isCancelled, self.isMonitoring else { break }
                                    
                                    let snapshot = self.visionAnalyzer.analyze(sampleBuffer: sampleBuffer)
                                    if let snapshot = snapshot {
                                        let assessment = self.postureAnalyzer.analyze(snapshot: snapshot, baseline: self.baseline)
                                        
                                        validFramesCount += 1
                                        if validFramesCount >= 3 {
                                            await MainActor.run {
                                                self.currentSnapshot   = snapshot
                                                self.currentAssessment = assessment
                                                self.postureScore  = assessment.score
                                                
                                                let log = PostureLog(score: assessment.score, issuesSummary: assessment.summaryText)
                                                self.modelContext?.insert(log)
                                                try? self.modelContext?.save()
                                            }
                                            break // Got a good reading, stop processing frames
                                        }
                                    }
                                }
                            }
                            
                            // Task 2: Strict hardware timeout clock
                            group.addTask {
                                try await Task.sleep(nanoseconds: 3_000_000_000)
                                throw CancellationError() // Timeout reached! Cancel the stream.
                            }
                            
                            // First task to finish wins, the other gets cancelled
                            _ = try await group.next()
                            group.cancelAll()
                        }
                    } catch {
                        Logger.services.info("Camera polling loop timed out (3.0s) — user away from desk or camera stuck.")
                    }
                    
                    cameraService.stop()
                    
                    await MainActor.run {
                        self.nextCheckTime = Date.now.addingTimeInterval(self.monitoringInterval)
                    }
                    
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
        cameraService?.stop()
        Logger.services.info("PostureService: stopMonitoring()")
    }

    deinit {
        frameTask?.cancel()
    }
}
