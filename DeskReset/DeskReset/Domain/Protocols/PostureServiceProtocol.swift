//
//  PostureServiceProtocol.swift
//  DeskReset
//
//  Protocol contract for camera & Vision-based posture monitoring.
//

import Foundation

public enum LastRunStatus: String, Codable, Sendable {
    case success = "Success"
    case personNotDetected = "No person detected"
    case noScanYet = "No scans yet"
}

/// Contract for Vision/camera-based posture monitoring.
protocol PostureServiceProtocol: AnyObject {
    /// Whether the posture monitoring session is active.
    var isMonitoring: Bool { get }
    /// Normalised posture score: 0 (poor) → 100 (excellent).
    var postureScore: Int { get }
    /// Human-readable posture status description.
    var statusDescription: String { get }
    /// Latest body pose snapshot captured by Vision framework.
    var currentSnapshot: PostureSnapshot? { get }
    /// Latest posture analysis assessment.
    var currentAssessment: PostureAssessment? { get }
    /// User's calibrated posture baseline.
    var baseline: PostureBaseline { get }
    
    var monitoringInterval: TimeInterval { get set }
    var nextCheckTime: Date? { get }
    
    /// The status of the last posture check run.
    var lastRunStatus: LastRunStatus { get }

    func updateBaseline(_ baseline: PostureBaseline)
    func startMonitoring()
    func stopMonitoring()
}
