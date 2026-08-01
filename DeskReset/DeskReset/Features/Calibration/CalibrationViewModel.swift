//
//  CalibrationViewModel.swift
//  DeskReset
//

import Foundation
import SwiftData
import Observation
import OSLog
import AVFoundation

// MARK: — Calibration Phase

enum CalibrationPhase: Equatable {
    case instructions
    case calibrating
    case completed(PostureBaseline)
    case failed(String)
    /// Camera access was explicitly denied in macOS Settings.
    /// macOS won't re-show the system prompt — user must go to System Settings > Privacy > Camera.
    case permissionDenied
}

// MARK: — Calibration Sample

private struct CalibrationSample {
    let headOffset: Double
    let shoulderTilt: Double
    let torsoLean: Double
    let shoulderWidthRatio: Double
    let shoulderZDiff: Double
}

// MARK: — ViewModel

@Observable
@MainActor
final class CalibrationViewModel {

    // MARK: - Published State
    var phase: CalibrationPhase = .instructions
    var remainingSeconds: Double = 10.0
    var progress: Double         = 0.0
    var currentSnapshot: PostureSnapshot? = nil
    var samplesCount: Int        = 0

    // MARK: - Private
    private var cameraService: (any CameraServiceProtocol)?
    private var postureService: (any PostureServiceProtocol)?
    private let visionAnalyzer = VisionPoseAnalyzer()

    private var samples: [CalibrationSample] = []
    private var calibrationTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var permissionCheckTask: Task<Void, Never>?

    // MARK: - Init
    init() {}

    // MARK: - Configure
    func configure(with serviceLocator: ServiceLocator) {
        self.cameraService  = serviceLocator.cameraService
        self.postureService = serviceLocator.postureService
        Logger.ui.info("CalibrationViewModel configured")
    }

    // MARK: - Permission Polling

    /// Starts a background task that polls AVCaptureDevice.authorizationStatus every 2 seconds.
    /// This is more reliable than NSApplication.didBecomeActiveNotification (which can miss events
    /// when CalibrationView is presented as a sheet).
    /// The loop exits automatically when permission is granted or the phase changes.
    private func startPermissionPolling() {
        permissionCheckTask?.cancel()
        permissionCheckTask = Task { @MainActor [weak self] in
            while true {
                // Wait 2 seconds between each check
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                guard let self, self.phase == .permissionDenied else { return }
                guard let cameraService = self.cameraService else { return }

                // requestPermission() reads AVCaptureDevice.authorizationStatus fresh from the OS.
                // It returns true immediately (no dialog) if the user just granted access in Settings.
                let granted = await cameraService.requestPermission()
                if granted {
                    self.phase = .instructions
                    Logger.ui.info("CalibrationViewModel: camera permission granted via polling — advancing to instructions")
                    return
                }
            }
        }
    }

    /// Manual trigger (e.g. from NSApplication.didBecomeActiveNotification) that checks
    /// permission immediately without waiting for the next 2-second poll cycle.
    func recheckPermission() {
        guard phase == .permissionDenied else { return }
        Task { @MainActor [weak self] in
            guard let self, let cameraService = self.cameraService else { return }
            let granted = await cameraService.requestPermission()
            if granted {
                self.phase = .instructions
                Logger.ui.info("CalibrationViewModel: camera permission granted on foreground — advancing to instructions")
            }
        }
    }

    // MARK: - Start Calibration

    func startCalibration(modelContext: ModelContext) {
        guard let cameraService else {
            phase = .failed("Camera service unavailable.")
            return
        }

        phase            = .calibrating
        remainingSeconds = 10.0
        progress         = 0.0
        samples.removeAll()
        samplesCount     = 0

        // Cancel any in-flight permission poll from a previous denial
        permissionCheckTask?.cancel()

        // 1. Ensure camera is authorized & running
        calibrationTask?.cancel()
        calibrationTask = Task { [weak self] in
            guard let self else { return }

            if !cameraService.isRunning {
                let granted = await cameraService.requestPermission()
                guard granted else {
                    // Distinguish "denied/restricted" (can't re-prompt, needs System Settings)
                    // from other failures where "Try Again" is still meaningful.
                    if cameraService.permissionStatus == .denied || cameraService.permissionStatus == .restricted {
                        self.phase = .permissionDenied
                        // Start background polling so the UI auto-updates when
                        // the user enables camera access in System Settings.
                        self.startPermissionPolling()
                    } else {
                        self.phase = .failed("Camera permission is required for calibration.")
                    }
                    return
                }
                try? await cameraService.start()
            }

            // 2. Start 10-second countdown timer
            self.startCountdownTimer(modelContext: modelContext)

            // 3. Process video frames
            let stream = cameraService.frameStream()
            for await sampleBuffer in stream {
                guard !Task.isCancelled else { break }

                let snapshot = self.visionAnalyzer.analyze(sampleBuffer: sampleBuffer)

                await MainActor.run {
                    self.currentSnapshot = snapshot
                    if let snap = snapshot, snap.isDetected {
                        self.recordSample(from: snap)
                    }
                }
            }
        }
    }

    // MARK: - Record Sample

    private func recordSample(from snapshot: PostureSnapshot) {
        guard let head = snapshot.head,
              let neck = snapshot.neck,
              let lShoulder = snapshot.leftShoulder,
              let rShoulder = snapshot.rightShoulder else {
            return
        }

        let headOffset = abs(Double(head.point.x - neck.point.x))
        let dxShoulders = Double(rShoulder.point.x - lShoulder.point.x)
        let dyShoulders = Double(rShoulder.point.y - lShoulder.point.y)
        let shoulderTilt = atan2(dyShoulders, dxShoulders) * (180.0 / .pi)

        let torsoPoint = snapshot.torso?.point ?? CGPoint(
            x: (lShoulder.point.x + rShoulder.point.x) / 2.0,
            y: (lShoulder.point.y + rShoulder.point.y) / 2.0 - 0.2
        )
        let dxTorso = Double(torsoPoint.x - neck.point.x)
        let dyTorso = Double(neck.point.y - torsoPoint.y)
        let torsoLean = atan2(dxTorso, max(dyTorso, 0.001)) * (180.0 / .pi)

        let shoulderWidth = hypot(dxShoulders, dyShoulders)
        let torsoHeight   = max(hypot(dxTorso, dyTorso), 0.05)
        let widthRatio    = shoulderWidth / torsoHeight
        
        let zDiff: Double
        if let lz = lShoulder.zDepth, let rz = rShoulder.zDepth {
            zDiff = Double(lz - rz)
        } else {
            zDiff = 0.0
        }

        samples.append(CalibrationSample(
            headOffset: headOffset,
            shoulderTilt: shoulderTilt,
            torsoLean: torsoLean,
            shoulderWidthRatio: widthRatio,
            shoulderZDiff: zDiff
        ))
        samplesCount = samples.count
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer(modelContext: ModelContext) {
        timerTask?.cancel()
        let totalDuration = 10.0
        let interval = 0.1

        timerTask = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { break }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.remainingSeconds -= interval
                    self.progress = min(1.0, (totalDuration - self.remainingSeconds) / totalDuration)

                    if self.remainingSeconds <= 0 {
                        self.finishCalibration(modelContext: modelContext)
                    }
                }
            }
        }
    }

    // MARK: - Finish Calibration

    private func finishCalibration(modelContext: ModelContext) {
        timerTask?.cancel()
        calibrationTask?.cancel()

        guard samples.count >= 10 else {
            phase = .failed("Could not detect body pose clearly. Please ensure you are visible in the camera frame.")
            return
        }

        // Calculate average baseline metrics
        let totalCount = Double(samples.count)
        let meanHeadOffset  = samples.reduce(0.0) { $0 + $1.headOffset } / totalCount
        let meanShoulderTilt = samples.reduce(0.0) { $0 + $1.shoulderTilt } / totalCount
        let meanTorsoLean   = samples.reduce(0.0) { $0 + $1.torsoLean } / totalCount
        let meanWidthRatio  = samples.reduce(0.0) { $0 + $1.shoulderWidthRatio } / totalCount
        let meanZDiff       = samples.reduce(0.0) { $0 + $1.shoulderZDiff } / totalCount

        let baseline = PostureBaseline(
            isCalibrated: true,
            calibratedAt: Date(),
            headOffset: meanHeadOffset,
            shoulderTilt: meanShoulderTilt,
            torsoLean: meanTorsoLean,
            shoulderWidthRatio: meanWidthRatio,
            shoulderZDiff: meanZDiff
        )

        // 1. Update PostureService
        postureService?.updateBaseline(baseline)

        // 2. Persist to SwiftData UserPreferences
        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let prefsList = try modelContext.fetch(descriptor)
            let prefs = prefsList.first ?? UserPreferences()

            if prefsList.isEmpty {
                modelContext.insert(prefs)
            }

            prefs.baseline = baseline
            try modelContext.save()
            Logger.data.info("Saved posture baseline calibration to SwiftData")
        } catch {
            Logger.data.error("Failed to save posture baseline to SwiftData: \(error)")
        }

        // 3. Stop camera if posture monitoring is not active
        if postureService?.isMonitoring == false {
            cameraService?.stop()
        }

        phase = .completed(baseline)
    }

    func cancel() {
        timerTask?.cancel()
        calibrationTask?.cancel()
        permissionCheckTask?.cancel()
        if postureService?.isMonitoring == false {
            cameraService?.stop()
        }
        phase = .instructions
    }
}
