//
//  PostureSnapshot.swift
//  DeskReset
//
//  Represents a single body pose detection frame captured by Vision framework.
//

import Foundation
import CoreGraphics

// MARK: — PostureJoint

public struct PostureJoint: Sendable, Equatable, Identifiable {
    public var id: String { name }

    /// Joint identifier (e.g. "Head", "Neck", "Left Shoulder")
    public let name: String
    /// Normalized coordinates from Vision: (0,0) at bottom-left, (1,1) at top-right
    public let point: CGPoint
    /// Vision detection confidence score: 0.0 → 1.0
    public let confidence: Float

    public init(name: String, point: CGPoint, confidence: Float) {
        self.name = name
        self.point = point
        self.confidence = confidence
    }

    /// Converts normalized Vision point (bottom-left origin) to SwiftUI canvas point (top-left origin).
    /// Option to mirror horizontally for front-facing camera preview.
    public func swiftUIPoint(in size: CGSize, isMirrored: Bool = true) -> CGPoint {
        let x = isMirrored ? (1.0 - point.x) : point.x
        let y = 1.0 - point.y // flip Y axis for SwiftUI coordinate system
        return CGPoint(
            x: x * size.width,
            y: y * size.height
        )
    }
}

// MARK: — PostureSnapshot

public struct PostureSnapshot: Sendable, Equatable {
    public let timestamp: Date

    // Extracted key joints
    public let head: PostureJoint?
    public let neck: PostureJoint?
    public let leftShoulder: PostureJoint?
    public let rightShoulder: PostureJoint?
    public let torso: PostureJoint?

    // Full list of detected joints
    public let allJoints: [PostureJoint]

    public var isDetected: Bool {
        neck != nil || leftShoulder != nil || rightShoulder != nil || head != nil
    }

    public var jointCount: Int {
        allJoints.count
    }

    public init(
        timestamp: Date = Date(),
        head: PostureJoint? = nil,
        neck: PostureJoint? = nil,
        leftShoulder: PostureJoint? = nil,
        rightShoulder: PostureJoint? = nil,
        torso: PostureJoint? = nil,
        allJoints: [PostureJoint] = []
    ) {
        self.timestamp = timestamp
        self.head = head
        self.neck = neck
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.torso = torso
        self.allJoints = allJoints
    }
}
