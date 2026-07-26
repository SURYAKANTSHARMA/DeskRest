//
//  CameraDebugView.swift
//  DeskReset
//
//  Debug screen: live camera preview + session diagnostics.
//  Frames are rendered by AVCaptureVideoPreviewLayer and are never saved.
//

import SwiftUI
import AVFoundation

struct CameraDebugView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = CameraDebugViewModel()

    var body: some View {
        HStack(spacing: 0) {
            previewPanel
            sidePanel
        }
        .frame(minWidth: 760, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.configure(with: serviceLocator)
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }

    // MARK: — Left: Live Camera Preview

    private var previewPanel: some View {
        ZStack {
            // Camera preview (or placeholder)
            if viewModel.isSessionRunning, let service = serviceLocator.cameraService {
                ZStack {
                    CameraPreviewView(session: service.captureSession)

                    // Vision Body Pose Overlay
                    PoseOverlayView(
                        snapshot: viewModel.currentSnapshot,
                        assessment: viewModel.currentAssessment
                    )
                }
                .clipShape(Rectangle())
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))

                // Live indicator overlay
                VStack {
                    HStack {
                        liveBadge
                        Spacer()
                        poseDetectedBadge
                    }
                    Spacer()
                    frameInfoOverlay
                }
                .padding(12)

            } else {
                placeholderPreview
            }
        }
        .frame(minWidth: 430)
        .background(Color.black)
        .overlay(alignment: .bottom) {
            previewControls
        }
    }

    // MARK: — Live Indicator

    private var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.statusError)
                .frame(width: 7, height: 7)
                .shadow(color: Color.statusError.opacity(0.7), radius: 4)
            Text("LIVE")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: — Frame Info Overlay

    private var frameInfoOverlay: some View {
        HStack(spacing: 12) {
            debugChip(
                icon: "film.stack",
                value: "\(viewModel.frameCount)",
                label: "frames"
            )
            debugChip(
                icon: "gauge.with.dots.needle.67percent",
                value: String(format: "%.1f", viewModel.fps),
                label: "fps"
            )
            if viewModel.frameWidth > 0 {
                debugChip(
                    icon: "aspectratio",
                    value: "\(viewModel.frameWidth)×\(viewModel.frameHeight)",
                    label: "resolution"
                )
            }
        }
    }

    private func debugChip(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Text(label)
                    .font(.caption2)
                    .opacity(0.7)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: — Placeholder

    private var placeholderPreview: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.indigo.opacity(0.6))
            }

            VStack(spacing: 6) {
                Text("Camera Preview")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(placeholderSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var placeholderSubtitle: String {
        switch viewModel.permissionStatus {
        case .notDetermined: return "Grant camera permission to begin"
        case .denied, .restricted: return "Camera access was denied.\nGo to System Settings → Privacy → Camera"
        case .authorized:
            return viewModel.isStartingSession ? "Starting session…" : "Tap Start Camera to begin preview"
        }
    }

    // MARK: — Bottom Preview Controls

    private var previewControls: some View {
        HStack(spacing: 12) {
            // Permission button (when needed)
            if viewModel.permissionStatus != .authorized {
                Button {
                    Task { await viewModel.requestPermission() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isRequestingPermission {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "camera.fill")
                        }
                        Text(viewModel.isRequestingPermission ? "Requesting…" : "Allow Camera")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .disabled(viewModel.isRequestingPermission)
            }

            // Start / Stop
            if viewModel.isSessionRunning {
                Button {
                    viewModel.stopSession()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Camera")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.statusError)
            } else {
                Button {
                    Task { await viewModel.startSession() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isStartingSession {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(viewModel.isStartingSession ? "Starting…" : "Start Camera")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.statusSuccess)
                .disabled(
                    viewModel.permissionStatus != .authorized || viewModel.isStartingSession
                )
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }

    private var poseDetectedBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "figure.walk")
                .font(.caption2)
            Text(viewModel.currentSnapshot?.isDetected == true ? "POSE DETECTED" : "SEARCHING POSE")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(viewModel.currentSnapshot?.isDetected == true ? Color.statusSuccess : Color.statusWarning)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: — Right: Diagnostics Side Panel

    private var sidePanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                panelHeader

                // Posture Analysis card
                infoSection(title: "Posture Analysis Engine") {
                    postureAssessmentCard
                }

                // Vision Body Pose card
                infoSection(title: "Vision Pose Detection") {
                    visionPoseCard
                }

                // Permission card
                infoSection(title: "System Permission") {
                    permissionCard
                }

                // Session card
                infoSection(title: "Capture Session") {
                    sessionCard
                }

                // Frame stream card
                infoSection(title: "Frame Stream") {
                    frameStreamCard
                }

                // Error card
                if let error = viewModel.lastError {
                    infoSection(title: "Last Error") {
                        errorCard(error)
                    }
                }

                Spacer(minLength: 0)

                privacyNote
            }
            .padding(18)
        }
        .frame(width: 300)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // Panel title
    private var panelHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Camera Debug")
                    .font(.headline)
                Text("Live Diagnostics")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    // MARK: — Info Sections

    private func infoSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.textTertiary)
                .tracking(1)
            content()
        }
    }

    // MARK: — Diagnostic Cards

    private var postureAssessmentCard: some View {
        let assessment = viewModel.currentAssessment
        let quality = assessment?.quality ?? .unknown
        let score = assessment?.score ?? 100

        return VStack(spacing: 8) {
            // Quality & Score row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: quality.icon)
                        .foregroundStyle(
                            quality == .good ? Color.statusSuccess :
                            (quality == .fair ? Color.statusWarning : Color.statusError)
                        )
                    Text(quality.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(nsColor: .labelColor))
                }
                Spacer()
                Text("\(score) pts")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.brandPrimary.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.brandPrimary)
            }

            Divider()

            // Active Issues
            if let issues = assessment?.issues, !issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE ISSUES")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.statusError)

                    ForEach(issues) { issue in
                        HStack(spacing: 6) {
                            Image(systemName: issue.type.icon)
                                .font(.caption2)
                                .foregroundStyle(Color.statusError)
                            Text(issue.type.rawValue)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color(nsColor: .labelColor))
                            Spacer()
                            Text(issue.severity.rawValue)
                                .font(.caption2)
                                .foregroundStyle(Color.statusError)
                        }
                    }
                }
                Divider()
            }

            // Smoothed Geometric Metrics
            diagRow(
                label: "Forward Head Offset",
                value: String(format: "%.3f", assessment?.forwardHeadOffset ?? 0.0)
            )
            Divider()
            diagRow(
                label: "Shoulder Tilt",
                value: String(format: "%.1f°", assessment?.shoulderImbalanceDegrees ?? 0.0)
            )
            Divider()
            diagRow(
                label: "Torso Lean",
                value: String(format: "%.1f°", assessment?.torsoLeanDegrees ?? 0.0)
            )
            Divider()
            diagRow(
                label: "Shoulder Width Ratio",
                value: String(format: "%.2f", assessment?.shoulderWidthRatio ?? 1.0)
            )
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var visionPoseCard: some View {
        let snapshot = viewModel.currentSnapshot
        return VStack(spacing: 8) {
            diagRow(
                label: "Request",
                value: "VNDetectHumanBodyPoseRequest",
                valueColor: .brandPrimary
            )
            Divider()
            diagRow(
                label: "Joints Detected",
                value: "\(snapshot?.jointCount ?? 0)",
                valueColor: (snapshot?.jointCount ?? 0) > 0 ? .statusSuccess : Color(nsColor: .systemGray)
            )
            Divider()
            diagRow(
                label: "Head",
                value: jointStatus(snapshot?.head)
            )
            Divider()
            diagRow(
                label: "Neck",
                value: jointStatus(snapshot?.neck)
            )
            Divider()
            diagRow(
                label: "Left Shoulder",
                value: jointStatus(snapshot?.leftShoulder)
            )
            Divider()
            diagRow(
                label: "Right Shoulder",
                value: jointStatus(snapshot?.rightShoulder)
            )
            Divider()
            diagRow(
                label: "Torso",
                value: jointStatus(snapshot?.torso)
            )
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func jointStatus(_ joint: PostureJoint?) -> String {
        guard let j = joint else { return "—" }
        let confPercent = Int(j.confidence * 100)
        return "Found (\(confPercent)%)"
    }

    private var permissionCard: some View {
        let color = permissionColor
        return HStack(spacing: 12) {
            Image(systemName: viewModel.permissionStatus.icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.permissionStatus.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.textPrimary)
                Text(permissionDescription)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }

    private var permissionColor: Color {
        switch viewModel.permissionStatus {
        case .authorized:    return .statusSuccess
        case .denied, .restricted: return .statusError
        case .notDetermined: return .statusWarning
        }
    }

    private var permissionDescription: String {
        switch viewModel.permissionStatus {
        case .authorized:    return "Camera access granted"
        case .denied:        return "Access denied — check System Settings"
        case .restricted:    return "Access restricted by policy"
        case .notDetermined: return "Permission not yet requested"
        }
    }

    private var sessionCard: some View {
        VStack(spacing: 8) {
            diagRow(
                label: "Status",
                value: viewModel.isSessionRunning ? "Running" : "Stopped",
                valueColor: viewModel.isSessionRunning ? .statusSuccess : Color(nsColor: .systemGray)
            )
            Divider()
            diagRow(label: "Preset", value: "Medium (AVCaptureSessionPreset)")
            Divider()
            diagRow(label: "Source", value: "Front / Built-in Camera")
            Divider()
            diagRow(label: "Output", value: "VideoDataOutput (no recording)")
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var frameStreamCard: some View {
        VStack(spacing: 8) {
            diagRow(
                label: "Total Frames",
                value: "\(viewModel.frameCount)",
                valueColor: viewModel.frameCount > 0 ? .brandPrimary : Color(nsColor: .systemGray)
            )
            Divider()
            diagRow(
                label: "FPS",
                value: viewModel.isSessionRunning
                    ? String(format: "%.1f", viewModel.fps)
                    : "—"
            )
            Divider()
            diagRow(
                label: "Resolution",
                value: viewModel.frameWidth > 0
                    ? "\(viewModel.frameWidth) × \(viewModel.frameHeight)"
                    : "—"
            )
            Divider()
            diagRow(label: "Pixel Format", value: "BGRA 32-bit")
            Divider()
            diagRow(label: "Saved to Disk", value: "Never ✓", valueColor: .statusSuccess)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func errorCard(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.statusError)
            Text(error)
                .font(.caption)
                .foregroundStyle(Color.statusError)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusError.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: — Privacy Note

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(Color.statusSuccess)
            Text("Frames are processed in-memory and **never saved to disk**. DeskReset does not record or transmit any video.")
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
        .padding(10)
        .background(Color.statusSuccess.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: — Diagnostic Row

    private func diagRow(
        label: String,
        value: String,
        valueColor: Color = Color(nsColor: .labelColor)
    ) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(valueColor)
        }
    }
}

#Preview {
    CameraDebugView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService(),
            cameraService: CameraService()
        ))
}
