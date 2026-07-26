//
//  CameraServiceProtocol.swift
//  DeskReset
//
//  Protocol-based contract for the camera service.
//  Keeps AVFoundation dependencies out of the domain layer.
//

import AVFoundation
import CoreMedia

// MARK: — Permission Status

enum CameraPermissionStatus: String {
    case notDetermined = "Not Determined"
    case authorized    = "Authorized"
    case denied        = "Denied"
    case restricted    = "Restricted"

    var isGranted: Bool { self == .authorized }

    var icon: String {
        switch self {
        case .notDetermined: return "questionmark.circle"
        case .authorized:    return "checkmark.circle.fill"
        case .denied:        return "xmark.circle.fill"
        case .restricted:    return "lock.circle.fill"
        }
    }

    init(avStatus: AVAuthorizationStatus) {
        switch avStatus {
        case .notDetermined: self = .notDetermined
        case .authorized:    self = .authorized
        case .denied:        self = .denied
        case .restricted:    self = .restricted
        @unknown default:    self = .denied
        }
    }
}

// MARK: — Camera Errors

enum CameraError: Error, LocalizedError {
    case permissionDenied
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case sessionAlreadyRunning
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:      return "Camera permission has not been granted."
        case .noCameraAvailable:     return "No camera device is available on this Mac."
        case .cannotAddInput:        return "Failed to attach the camera input to the session."
        case .cannotAddOutput:       return "Failed to attach the frame output to the session."
        case .sessionAlreadyRunning: return "The capture session is already running."
        case .unknown(let e):        return "An unexpected error occurred: \(e.localizedDescription)"
        }
    }
}

// MARK: — Protocol

/// Contract for the camera capture service.
/// Exposes permission management, session lifecycle, and a frame stream.
/// Frames are delivered as raw `CMSampleBuffer` values and are NEVER saved to disk.
protocol CameraServiceProtocol: AnyObject {
    /// Whether the AVCaptureSession is actively running.
    var isRunning: Bool { get }
    /// Current system permission state.
    var permissionStatus: CameraPermissionStatus { get }
    /// The underlying AVCaptureSession — exposed only for preview layer attachment.
    var captureSession: AVCaptureSession { get }

    /// Request system camera permission. Returns `true` if authorized.
    func requestPermission() async -> Bool
    /// Configure and start the AVCaptureSession. Throws `CameraError` on failure.
    func start() async throws
    /// Stop the capture session and finish any open frame streams.
    func stop()
    /// Returns an `AsyncStream` that yields raw video frames.
    /// Frames are never written to disk — consume and discard immediately.
    func frameStream() -> AsyncStream<CMSampleBuffer>
}
