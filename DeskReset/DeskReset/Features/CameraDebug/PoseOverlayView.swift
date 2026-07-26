//
//  PoseOverlayView.swift
//  DeskReset
//
//  SwiftUI view overlay that renders detected human body pose keypoints
//  and skeleton lines over the camera video preview, dynamically highlighting
//  posture defects.
//

import SwiftUI

struct PoseOverlayView: View {

    let snapshot: PostureSnapshot?
    var assessment: PostureAssessment? = nil
    var isMirrored: Bool = true
    var showLabels: Bool = true

    var body: some View {
        GeometryReader { geometry in
            if let snapshot = snapshot, snapshot.isDetected {
                ZStack {
                    // 1. Draw skeleton connection lines
                    skeletonCanvas(in: geometry.size, snapshot: snapshot)

                    // 2. Draw keypoint joint markers
                    jointMarkers(in: geometry.size, snapshot: snapshot)
                }
                .animation(.linear(duration: 0.08), value: snapshot.timestamp)
            }
        }
    }

    // MARK: — Posture Issue Checks

    private var hasForwardHead: Bool {
        assessment?.issues.contains(where: { $0.type == .forwardHead }) ?? false
    }

    private var hasShoulderImbalance: Bool {
        assessment?.issues.contains(where: { $0.type == .shoulderImbalance }) ?? false
    }

    private var hasTorsoLean: Bool {
        assessment?.issues.contains(where: { $0.type == .torsoLean }) ?? false
    }

    private var hasRoundedShoulders: Bool {
        assessment?.issues.contains(where: { $0.type == .roundedShoulders }) ?? false
    }

    // MARK: — Skeleton Connections Canvas

    private func skeletonCanvas(in size: CGSize, snapshot: PostureSnapshot) -> some View {
        let headColor: Color = hasForwardHead ? .statusError : .cyan
        let shoulderColor: Color = (hasShoulderImbalance || hasRoundedShoulders) ? .statusError : .indigo
        let torsoColor: Color = hasTorsoLean ? .statusWarning : .teal

        return Canvas { context, _ in
            let connections: [(PostureJoint?, PostureJoint?, Color, CGFloat)] = [
                // Head -> Neck
                (snapshot.head, snapshot.neck, headColor, 3.5),
                // Neck -> Left Shoulder
                (snapshot.neck, snapshot.leftShoulder, shoulderColor, 3.5),
                // Neck -> Right Shoulder
                (snapshot.neck, snapshot.rightShoulder, shoulderColor, 3.5),
                // Left Shoulder -> Right Shoulder
                (snapshot.leftShoulder, snapshot.rightShoulder, shoulderColor, 3.0),
                // Left Shoulder -> Torso
                (snapshot.leftShoulder, snapshot.torso, torsoColor, 3.0),
                // Right Shoulder -> Torso
                (snapshot.rightShoulder, snapshot.torso, torsoColor, 3.0)
            ]

            // Render main skeleton connections
            for (start, end, color, width) in connections {
                guard let p1 = start?.swiftUIPoint(in: size, isMirrored: isMirrored),
                      let p2 = end?.swiftUIPoint(in: size, isMirrored: isMirrored) else {
                    continue
                }

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)

                // Glow background line
                context.stroke(
                    path,
                    with: .color(color.opacity(0.4)),
                    lineWidth: width + 4
                )
                // Core line
                context.stroke(
                    path,
                    with: .color(color),
                    lineWidth: width
                )
            }
        }
    }

    // MARK: — Joint Markers

    private func jointMarkers(in size: CGSize, snapshot: PostureSnapshot) -> some View {
        let headColor: Color = hasForwardHead ? .statusError : .cyan
        let neckColor: Color = hasForwardHead ? .statusError : .yellow
        let shoulderColor: Color = (hasShoulderImbalance || hasRoundedShoulders) ? .statusError : .indigo
        let torsoColor: Color = hasTorsoLean ? .statusWarning : .teal

        let keyJoints: [(PostureJoint?, String, Color)] = [
            (snapshot.head, "Head", headColor),
            (snapshot.neck, "Neck", neckColor),
            (snapshot.leftShoulder, "L. Shoulder", shoulderColor),
            (snapshot.rightShoulder, "R. Shoulder", shoulderColor),
            (snapshot.torso, "Torso", torsoColor)
        ]

        return ForEach(keyJoints.compactMap { j, label, color in
            j.map { ($0, label, color) }
        }, id: \.0.name) { joint, label, color in
            let pos = joint.swiftUIPoint(in: size, isMirrored: isMirrored)

            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 22, height: 22)

                // Inner joint node
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 1.5)
                    )

                // Label tag
                if showLabels {
                    Text(label)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 4))
                        .offset(y: -18)
                }
            }
            .position(pos)
        }
    }
}
