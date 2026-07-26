//
//  CameraDebugViewModel.swift
//  DeskReset
//

import Foundation
import AVFoundation
import CoreMedia
import Observation
import OSLog

@Observable
@MainActor
final class CameraDebugViewModel {

    // MARK: - State
    var permissionStatus: CameraPermissionStatus = .notDetermined
    var isSessionRunning: Bool  = false
    var frameCount: Int         = 0
    var fps: Double             = 0.0
    var frameWidth: Int         = 0
    var frameHeight: Int        = 0
    var lastError: String?      = nil
    var isRequestingPermission: Bool = false
    var isStartingSession: Bool = false

    // Vision Body Pose & Posture Assessment State
    var currentSnapshot: PostureSnapshot?   = nil
    var currentAssessment: PostureAssessment? = nil

    // MARK: - Private
    private var cameraService: (any CameraServiceProtocol)?
    private var postureService: (any PostureServiceProtocol)?
    private let visionAnalyzer  = VisionPoseAnalyzer()
    private let postureAnalyzer = PostureAnalyzer()
    private var frameStreamTask: Task<Void, Never>?

    // FPS calculation
    private var frameTimestamps: [Date] = []
    private let fpsWindowSize = 30   // rolling average over last 30 frames

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.cameraService  = serviceLocator.cameraService
        self.postureService = serviceLocator.postureService
        permissionStatus    = cameraService?.permissionStatus ?? .notDetermined
        isSessionRunning    = cameraService?.isRunning ?? false
        Logger.ui.info("CameraDebugViewModel configured")
    }

    // MARK: - Permission

    func requestPermission() async {
        guard let service = cameraService else { return }
        isRequestingPermission = true
        let granted = await service.requestPermission()
        permissionStatus       = service.permissionStatus
        isRequestingPermission = false
        Logger.ui.info("Camera permission result: \(granted)")
    }

    // MARK: - Session Control

    func startSession() async {
        guard let service = cameraService else { return }
        guard permissionStatus == .authorized else {
            lastError = "Camera permission required. Tap 'Allow Camera' first."
            return
        }
        isStartingSession = true
        do {
            try await service.start()
            isSessionRunning = service.isRunning
            lastError        = nil
            beginFrameConsumption(from: service)
        } catch {
            lastError        = error.localizedDescription
            isSessionRunning = false
            Logger.ui.error("Camera session start failed: \(error)")
        }
        isStartingSession = false
    }

    func stopSession() {
        cameraService?.stop()
        isSessionRunning  = false
        frameStreamTask?.cancel()
        frameStreamTask   = nil
        frameCount        = 0
        fps               = 0
        currentSnapshot   = nil
        currentAssessment = nil
        frameTimestamps.removeAll()
    }

    // MARK: - Frame Consumption & Pose Analysis

    private func beginFrameConsumption(from service: any CameraServiceProtocol) {
        frameStreamTask?.cancel()
        frameStreamTask = Task { [weak self] in
            let stream = service.frameStream()
            for await buffer in stream {
                guard !Task.isCancelled else { break }

                // 1. Detect Vision body pose
                let snapshot = self?.visionAnalyzer.analyze(sampleBuffer: buffer)

                // 2. Perform posture analysis & smoothing
                let assessment = snapshot.map { self?.postureAnalyzer.analyze(snapshot: $0) } ?? nil

                await self?.processFrame(buffer, snapshot: snapshot, assessment: assessment)
            }
        }
    }

    private func processFrame(_ buffer: CMSampleBuffer, snapshot: PostureSnapshot?, assessment: PostureAssessment?) {
        frameCount += 1
        currentSnapshot   = snapshot
        currentAssessment = assessment

        // FPS calculation — rolling window
        let now = Date()
        frameTimestamps.append(now)
        if frameTimestamps.count > fpsWindowSize {
            frameTimestamps.removeFirst()
        }
        if frameTimestamps.count >= 2 {
            let elapsed = now.timeIntervalSince(frameTimestamps.first!)
            fps = elapsed > 0 ? Double(frameTimestamps.count - 1) / elapsed : 0
        }

        // Extract frame dimensions from the image buffer
        if let imageBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let w = CVPixelBufferGetWidth(imageBuffer)
            let h = CVPixelBufferGetHeight(imageBuffer)
            if w != frameWidth || h != frameHeight {
                frameWidth  = w
                frameHeight = h
            }
        }
    }

    // MARK: - Cleanup
    nonisolated func cleanUp() {
        // Called from onDisappear
    }
}
