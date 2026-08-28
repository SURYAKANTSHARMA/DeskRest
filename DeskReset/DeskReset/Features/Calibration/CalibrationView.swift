//
//  CalibrationView.swift
//  DeskReset
//
//  Interactive 10-second posture calibration sheet.
//  Guides the user through capturing their neutral desk sitting baseline.
//

import SwiftUI
import SwiftData
import AppKit

struct CalibrationView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CalibrationViewModel()
    @State private var calibrationStartTime: Date? = nil

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            mainContent
        }
        .frame(width: 580, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.configure(with: serviceLocator)
            calibrationStartTime = Date()
            AnalyticsService.shared.log(.calibrationStarted(source: "dashboard"))
        }
        .onDisappear {
            viewModel.cancel()
        }
        // When the user returns from System Settings, silently re-check if
        // camera permission was granted and auto-advance back to .instructions.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.recheckPermission()
        }
    }

    // MARK: — Header Bar

    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
                Text("Posture Baseline Calibration")
                    .font(.headline)
            }
            Spacer()
            Button {
                AnalyticsService.shared.log(.calibrationCancelled)
                viewModel.cancel()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: — Main Content Switcher

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.phase {
        case .instructions:
            instructionsView
        case .calibrating:
            calibratingView
        case .completed(let baseline):
            completedView(baseline)
        case .failed(let message):
            failedView(message)
        case .permissionDenied:
            permissionDeniedView
        }
    }

    // MARK: — Instructions View

    private var instructionsView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "figure.seated.side.left")
                    .font(.system(size: 42))
                    .foregroundStyle(.brandPrimary)
            }

            VStack(spacing: 10) {
                Text("Set Your Healthy Baseline")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.textPrimary)

                Text("Sit comfortably in your ideal, upright desk posture looking straight at your screen. DeskReset will measure your posture over 10 seconds to create your personal baseline.")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Keep your head up and chin parallel to the floor")
                bulletPoint("Relax your shoulders back and down")
                bulletPoint("Sit with your back supported and feet flat")
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            HStack(spacing: 14) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    viewModel.startCalibration(modelContext: modelContext)
                } label: {
                    Label("Begin 10s Calibration", systemImage: "play.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.statusSuccess)
            Text(text)
                .font(.caption)
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: — Calibrating Live View

    private var calibratingView: some View {
        ZStack {
            // Live camera preview with pose overlay
            if let service = serviceLocator.cameraService {
                ZStack {
                    CameraPreviewView(session: service.captureSession)
                    PoseOverlayView(snapshot: viewModel.currentSnapshot)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(20)
            }

            // Overlay timer UI
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.statusError)
                            .frame(width: 8, height: 8)
                        Text("CALIBRATING...")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    Text("\(viewModel.samplesCount) pose samples")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(32)

                Spacer()

                // Progress Bar & Countdown
                VStack(spacing: 8) {
                    Text("\(Int(ceil(viewModel.remainingSeconds)))s")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    Text("Hold your neutral posture...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))

                    ProgressView(value: viewModel.progress)
                        .tint(.brandPrimary)
                        .padding(.horizontal, 40)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: — Completed View

    private func completedView(_ baseline: PostureBaseline) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.statusSuccess.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.statusSuccess)
            }

            VStack(spacing: 8) {
                Text("Calibration Complete! 🎉")
                    .font(.title2.weight(.bold))
                Text("DeskReset has learned your healthy sitting baseline. Future analysis will be customized to your body.")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            // Calibrated Metrics Grid
            VStack(spacing: 8) {
                baselineRow(label: "Neutral Head Offset", value: String(format: "%.3f", baseline.headOffset))
                Divider()
                baselineRow(label: "Shoulder Alignment", value: String(format: "%.1f°", baseline.shoulderTilt))
                Divider()
                baselineRow(label: "Torso Tilt Angle", value: String(format: "%.1f°", baseline.torsoLean))
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 420)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.statusSuccess)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    private func baselineRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.textPrimary)
        }
    }

    // MARK: — Failed View

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.statusError.opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.statusError)
            }

            VStack(spacing: 8) {
                Text("Calibration Failed")
                    .font(.title2.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            Spacer()

            HStack(spacing: 14) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Try Again") {
                    viewModel.startCalibration(modelContext: modelContext)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: — Permission Denied View


    /// Shown when the user has explicitly denied camera access in macOS.
    /// macOS will NEVER re-show the system permission dialog once denied —
    /// the only fix is a manual trip to System Settings > Privacy & Security > Camera.
    private var permissionDeniedView: some View {
        VStack(spacing: 0) {

            // ── Scrollable content (adapts to any frame height) ──────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.statusError.opacity(0.12))
                            .frame(width: 68, height: 68)
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 30))
                            .foregroundStyle(.statusError)
                    }
                    .padding(.top, 20)

                    // Title + description
                    VStack(spacing: 6) {
                        Text("Camera Access Denied")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.textPrimary)

                        Text("DeskReset needs camera access to detect your posture. macOS has blocked it — enable it in System Settings to continue.")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Numbered steps card
                    VStack(alignment: .leading, spacing: 8) {
                        stepRow("1", "Tap \"Open System Settings\" below")
                        stepRow("2", "Go to Privacy & Security → Camera")
                        stepRow("3", "Enable the toggle next to DeskReset")
                        stepRow("4", "Return here — screen auto-updates ✓")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.statusError.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
            }

            // ── Pinned button area — always visible ───────────────────────────
            Divider()

            VStack(spacing: 10) {
                // Primary action
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open System Settings → Camera", systemImage: "gear")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.statusError)
                .controlSize(.large)

                // Secondary actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity)

                    Button("Try Calibration Again") {
                        viewModel.startCalibration(modelContext: modelContext)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private func stepRow(_ number: String, _ label: String) -> some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(Color.brandPrimary.opacity(0.15), in: Circle())
                .foregroundStyle(.brandPrimary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.textPrimary)
        }
    }
}

#Preview {
    CalibrationView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService(),
            cameraService: CameraService()
        ))
}
