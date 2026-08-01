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
    private var request3D: VNRequest? = nil

    init() {
        if #available(macOS 14.0, *) {
            request3D = VNDetectHumanBodyPose3DRequest()
        }
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
            Logger.services.error("Vision 2D body pose request failed: \(error)")
            return nil
        }
        
        if let req3D = request3D {
            do {
                try handler.perform([req3D])
            } catch {
                // Ignore 3D errors (e.g. ABPK unsupported on some devices), we'll just fall back to 2D
                Logger.services.debug("Vision 3D request skipped/failed: \(error)")
            }
        }

        guard let observation = request.results?.first else {
            return nil
        }

        var obs3D: Any? = nil
        if #available(macOS 14.0, *) {
            obs3D = request3D?.results?.first as? VNHumanBodyPose3DObservation
        }

        return extractSnapshot(from: observation, obs3D: obs3D)
    }

    // MARK: — Joint Extraction

    private func extractSnapshot(from observation: VNHumanBodyPoseObservation, obs3D: Any?) -> PostureSnapshot {
        // Minimum confidence threshold for joint acceptance
        let minConfidence: Float = 0.15

        func joint(_ key: VNHumanBodyPoseObservation.JointName, name: String, key3D: Any? = nil) -> PostureJoint? {
            guard let pt = try? observation.recognizedPoint(key), pt.confidence >= minConfidence else {
                return nil
            }
            var zDepth: Float? = nil
            if #available(macOS 14.0, *) {
                if let obs = obs3D as? VNHumanBodyPose3DObservation,
                   let k3 = key3D as? VNHumanBodyPose3DObservation.JointName,
                   let pt3D = try? obs.recognizedPoint(k3) {
                    zDepth = pt3D.position.columns.3.z
                }
            }
            return PostureJoint(name: name, point: pt.location, confidence: pt.confidence, zDepth: zDepth)
        }

        // 1. Head (Nose or eyes/ears)
        let head = joint(.nose, name: "Head", key3D: {
            if #available(macOS 14.0, *) { return VNHumanBodyPose3DObservation.JointName.centerHead } else { return nil }
        }()) ?? joint(.leftEye, name: "Head")

        // 2. Neck
        let neck = joint(.neck, name: "Neck") // 3D neck not strictly needed for this, but could be mapped

        // 3. Left Shoulder
        let leftShoulder = joint(.leftShoulder, name: "Left Shoulder", key3D: {
            if #available(macOS 14.0, *) { return VNHumanBodyPose3DObservation.JointName.leftShoulder } else { return nil }
        }())

        // 4. Right Shoulder
        let rightShoulder = joint(.rightShoulder, name: "Right Shoulder", key3D: {
            if #available(macOS 14.0, *) { return VNHumanBodyPose3DObservation.JointName.rightShoulder } else { return nil }
        }())

        // 5. Torso (Root / Hip midpoint)
        let torso = joint(.root, name: "Torso", key3D: {
            if #available(macOS 14.0, *) { return VNHumanBodyPose3DObservation.JointName.root } else { return nil }
        }()) ?? joint(.leftHip, name: "Torso")

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
