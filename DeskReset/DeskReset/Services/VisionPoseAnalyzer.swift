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
        
        // Fast-fail: If the 2D request found nothing, don't run the heavy 3D math!
        guard let observation = request.results?.first else {
            return nil
        }

        // Extract key body joints needed for ergonomic posture analysis
        let jointKeys: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .neck,
            .leftShoulder,
            .rightShoulder,
            .root,
            .leftEar,
            .rightEar
        ]

        var recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
        for key in jointKeys {
            if let point = try? observation.recognizedPoint(key), point.confidence > 0.3 {
                recognizedPoints[key] = point
            }
        }

        // Require minimum keypoints for a valid posture assessment
        guard let neckPoint  = recognizedPoints[.neck],
              let lShoulder  = recognizedPoints[.leftShoulder],
              let rShoulder  = recognizedPoints[.rightShoulder] else {
            return nil
        }

        let headPoint = recognizedPoints[.nose] ?? recognizedPoints[.neck]

        // --- 3D Depth Detection for Torso Rotation (macOS 14+) ---
        var lShoulderZ: Float? = nil
        var rShoulderZ: Float? = nil

        if #available(macOS 14.0, *), let req3D = request3D as? VNDetectHumanBodyPose3DRequest {
            do {
                try handler.perform([req3D])
                if let obs3D = req3D.results?.first {
                    if let pLeft = try? obs3D.recognizedPoint(.leftShoulder) {
                        // camera-relative position vector in meters (x, y, z)
                        lShoulderZ = pLeft.position.columns.3.z
                    }
                    if let pRight = try? obs3D.recognizedPoint(.rightShoulder) {
                        rShoulderZ = pRight.position.columns.3.z
                    }
                }
            } catch {
                // 3D pose detection failed gracefully — fallback to 2D ratio estimation
            }
        }

        let headJoint = headPoint.map { PostureJoint(name: "Head", point: $0.location, confidence: $0.confidence) }
        let neckJoint = PostureJoint(name: "Neck", point: neckPoint.location, confidence: neckPoint.confidence)
        let leftShoulderJoint = PostureJoint(
            name: "Left Shoulder",
            point: lShoulder.location,
            confidence: lShoulder.confidence,
            zDepth: lShoulderZ
        )
        let rightShoulderJoint = PostureJoint(
            name: "Right Shoulder",
            point: rShoulder.location,
            confidence: rShoulder.confidence,
            zDepth: rShoulderZ
        )
        let torsoJoint = recognizedPoints[.root].map {
            PostureJoint(name: "Torso", point: $0.location, confidence: $0.confidence)
        }

        var allJoints: [PostureJoint] = [neckJoint, leftShoulderJoint, rightShoulderJoint]
        if let h = headJoint { allJoints.append(h) }
        if let t = torsoJoint { allJoints.append(t) }

        return PostureSnapshot(
            timestamp: Date(),
            head: headJoint,
            neck: neckJoint,
            leftShoulder: leftShoulderJoint,
            rightShoulder: rightShoulderJoint,
            torso: torsoJoint,
            allJoints: allJoints
        )
    }
}
