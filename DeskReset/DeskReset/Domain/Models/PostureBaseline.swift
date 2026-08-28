//
//  PostureBaseline.swift
//  DeskReset
//
//  Represents the user's calibrated neutral posture baseline values.
//

import Foundation

public struct PostureBaseline: Sendable, Codable, Equatable {
    public var isCalibrated: Bool
    public var calibratedAt: Date?
    public var headOffset: Double
    public var shoulderTilt: Double
    public var torsoLean: Double
    public var shoulderWidthRatio: Double
    public var shoulderZDiff: Double

    public nonisolated static let uncalibrated = PostureBaseline(
        isCalibrated: false,
        calibratedAt: nil,
        headOffset: 0.0,
        shoulderTilt: 0.0,
        torsoLean: 0.0,
        shoulderWidthRatio: 1.0,
        shoulderZDiff: 0.0
    )

    public init(
        isCalibrated: Bool = false,
        calibratedAt: Date? = nil,
        headOffset: Double = 0.0,
        shoulderTilt: Double = 0.0,
        torsoLean: Double = 0.0,
        shoulderWidthRatio: Double = 1.0,
        shoulderZDiff: Double = 0.0
    ) {
        self.isCalibrated = isCalibrated
        self.calibratedAt = calibratedAt
        self.headOffset = headOffset
        self.shoulderTilt = shoulderTilt
        self.torsoLean = torsoLean
        self.shoulderWidthRatio = shoulderWidthRatio
        self.shoulderZDiff = shoulderZDiff
    }
}
