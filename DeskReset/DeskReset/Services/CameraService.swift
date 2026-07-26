//
//  CameraService.swift
//  DeskReset
//
//  Concrete AVFoundation implementation of CameraServiceProtocol.
//  Frames are delivered through AsyncStream<CMSampleBuffer>.
//  Frames are NEVER saved to disk — they are consumed in-memory and discarded.
//  Automatically turns OFF the camera when frame stream terminates or stop() is called.
//

import AVFoundation
import CoreMedia
import Observation
import OSLog

// MARK: — Frame Handler (isolated from MainActor)

/// Bridges AVCaptureVideoDataOutputSampleBufferDelegate to AsyncStream.
/// Must be an NSObject and is explicitly @unchecked Sendable because
/// its single mutable property (continuation) is only accessed from the
/// dedicated output DispatchQueue.
private final class FrameHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    var continuation: AsyncStream<CMSampleBuffer>.Continuation?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        continuation?.yield(sampleBuffer)
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Late frames are silently dropped — alwaysDiscardsLateVideoFrames handles this
    }
}

// MARK: — Camera Service

@Observable
final class CameraService: CameraServiceProtocol {

    // MARK: - Observable State (main-actor accessed)
    var isRunning: Bool              = false
    var permissionStatus: CameraPermissionStatus
    var lastError: String?           = nil

    // MARK: - AVFoundation objects
    // nonisolated(unsafe) allows these to be safely accessed from the session /
    // output DispatchQueues without triggering MainActor isolation errors.
    nonisolated(unsafe) private let _session     = AVCaptureSession()
    nonisolated(unsafe) private let frameHandler = FrameHandler()
    nonisolated        private let sessionQueue  = DispatchQueue(
        label: "com.deskreset.camera.session", qos: .userInitiated)
    nonisolated        private let outputQueue   = DispatchQueue(
        label: "com.deskreset.camera.output",  qos: .userInitiated)

    // MARK: - Protocol: captureSession
    var captureSession: AVCaptureSession { _session }

    // MARK: - Init
    init() {
        let avStatus = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatus = CameraPermissionStatus(avStatus: avStatus)
        Logger.services.info("CameraService init — permission: \(avStatus.rawValue)")
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        switch current {
        case .authorized:
            permissionStatus = .authorized
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permissionStatus = granted ? .authorized : .denied
            Logger.services.info("Camera permission request result: \(granted)")
            return granted
        case .denied:
            permissionStatus = .denied
            return false
        case .restricted:
            permissionStatus = .restricted
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Session Lifecycle

    func start() async throws {
        guard permissionStatus == .authorized else {
            Logger.services.error("CameraService.start() called without permission")
            throw CameraError.permissionDenied
        }
        guard !_session.isRunning else {
            Logger.services.warning("CameraService.start() — session already running")
            return
        }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else { return }
                do {
                    if self._session.inputs.isEmpty {
                        try self.configureSession()
                    }
                    self._session.startRunning()
                    let running = self._session.isRunning
                    DispatchQueue.main.async {
                        self.isRunning = running
                        self.lastError = nil
                    }
                    Logger.services.info("CameraService: session started — running=\(running)")
                    cont.resume()
                } catch {
                    DispatchQueue.main.async {
                        self.lastError = error.localizedDescription
                    }
                    Logger.services.error("CameraService.start() failed: \(error)")
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self._session.isRunning {
                self._session.stopRunning()
            }
            self.frameHandler.continuation?.finish()
            self.frameHandler.continuation = nil
            DispatchQueue.main.async {
                self.isRunning = false
            }
            Logger.services.info("CameraService: session stopped — camera is OFF")
        }
    }

    // MARK: - Frame Stream

    /// Returns an AsyncStream that yields CMSampleBuffer frames from the camera.
    /// When the stream is terminated, the camera session automatically stops.
    func frameStream() -> AsyncStream<CMSampleBuffer> {
        AsyncStream { [weak self, frameHandler] continuation in
            frameHandler.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                Logger.services.info("Camera frame stream terminated — turning camera off")
                Task { @MainActor [weak self] in
                    self?.stop()
                }
            }
        }
    }

    // MARK: - Session Configuration

    private func configureSession() throws {
        _session.beginConfiguration()
        _session.sessionPreset = .medium

        // --- Input: prefer front camera, fall back to any available camera ---
        let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: .front
        ) ?? AVCaptureDevice.default(for: .video)

        guard let camera = device else {
            _session.commitConfiguration()
            throw CameraError.noCameraAvailable
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard _session.canAddInput(input) else {
            _session.commitConfiguration()
            throw CameraError.cannotAddInput
        }
        _session.addInput(input)

        // --- Output: video frames only — NO photo / NO file recording ---
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        // Discard late frames rather than blocking the pipeline
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(frameHandler, queue: outputQueue)

        guard _session.canAddOutput(output) else {
            _session.commitConfiguration()
            throw CameraError.cannotAddOutput
        }
        _session.addOutput(output)

        _session.commitConfiguration()
        Logger.services.info("CameraService: session configured — camera: \(camera.localizedName)")
    }
}
