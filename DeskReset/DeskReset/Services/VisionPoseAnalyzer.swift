//
//  VisionPoseAnalyzer.swift
//  DeskReset
//
//  Wraps Apple's Vision framework (VNDetectHumanBodyPoseRequest)
//  to extract human body pose joints from CMSampleBuffer camera frames.
//

import Vision
import CoreMedia
import OSLog

final class VisionPoseAnalyzer: @unchecked Sendable {

    private let request = VNDetectHumanBodyPoseRequest()

    init() {
        // Request body pose detection
    }

    /// Performs Vision body pose detection on a single camera sample buffer.
    /// Returns a PostureSnapshot containing extracted joint points.
    func analyze(sampleBuffer: CMSampleBuffer) -> PostureSnapshot? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            Logger.services.error("Vision body pose request failed: \(error)")
            return nil
        }

        guard let observation = request.results?.first else {
            return nil
        }

        return extractSnapshot(from: observation)
    }

    // MARK: — Joint Extraction

    private func extractSnapshot(from observation: VNHumanBodyPoseObservation) -> PostureSnapshot {
        // Minimum confidence threshold for joint acceptance
        let minConfidence: Float = 0.15

        func joint(_ key: VNHumanBodyPoseObservation.JointName, name: String) -> PostureJoint? {
            guard let pt = try? observation.recognizedPoint(key), pt.confidence >= minConfidence else {
                return nil
            }
            return PostureJoint(name: name, point: pt.location, confidence: pt.confidence)
        }

        // 1. Head (Nose or eyes/ears)
        let head = joint(.nose, name: "Head") ?? joint(.leftEye, name: "Head")

        // 2. Neck
        let neck = joint(.neck, name: "Neck")

        // 3. Left Shoulder
        let leftShoulder = joint(.leftShoulder, name: "Left Shoulder")

        // 4. Right Shoulder
        let rightShoulder = joint(.rightShoulder, name: "Right Shoulder")

        // 5. Torso (Root / Hip midpoint)
        let torso = joint(.root, name: "Torso") ?? joint(.leftHip, name: "Torso")

        // Collect all available body joints for overlay rendering
        var all: [PostureJoint] = []

        let keysToExtract: [(VNHumanBodyPoseObservation.JointName, String)] = [
            (.nose, "Nose"),
            (.leftEye, "Left Eye"), (.rightEye, "Right Eye"),
            (.leftEar, "Left Ear"), (.rightEar, "Right Ear"),
            (.neck, "Neck"),
            (.leftShoulder, "Left Shoulder"), (.rightShoulder, "Right Shoulder"),
            (.leftElbow, "Left Elbow"), (.rightElbow, "Right Elbow"),
            (.leftWrist, "Left Wrist"), (.rightWrist, "Right Wrist"),
            (.root, "Torso"),
            (.leftHip, "Left Hip"), (.rightHip, "Right Hip")
        ]

        for (key, label) in keysToExtract {
            if let j = joint(key, name: label) {
                all.append(j)
            }
        }

        return PostureSnapshot(
            timestamp: Date(),
            head: head,
            neck: neck,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            torso: torso,
            allJoints: all
        )
    }
}
