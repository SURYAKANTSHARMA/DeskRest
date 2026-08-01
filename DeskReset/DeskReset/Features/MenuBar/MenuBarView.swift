//
//  MenuBarView.swift
//  DeskReset
//
//  Compact popover shown when clicking the menu-bar icon.
//

import SwiftUI

struct MenuBarView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.openWindow) private var openWindow

    @State private var viewModel = MenuBarViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBanner
            statusPill
            Divider().padding(.horizontal, 14)
            actionRows
        }
        .frame(width: 296)
        .background(.regularMaterial)
        .onAppear {
            viewModel.configure(with: serviceLocator)
        }
    }

    // MARK: — Header Banner

    private var headerBanner: some View {
        HStack(spacing: 11) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: Color.brandGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "figure.walk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("DeskReset")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.statusMessage)
            }

            Spacer()

            // Monitoring state badge
            monitoringBadge
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var monitoringBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(monitoringDotColor)
                .frame(width: 7, height: 7)
                .shadow(color: monitoringDotColor.opacity(0.6), radius: 3)
            Text(viewModel.monitoringState.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(monitoringDotColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(monitoringDotColor.opacity(0.12), in: Capsule())
        .animation(.easeInOut(duration: 0.25), value: viewModel.monitoringState)
    }

    private var monitoringDotColor: Color {
        switch viewModel.monitoringState {
        case .active:   return .statusSuccess
        case .paused:   return .statusWarning
        case .inactive: return Color(nsColor: .systemGray)
        }
    }

    // MARK: — Status Pill (quick stats when monitoring)

    @ViewBuilder
    private var statusPill: some View {
        if viewModel.isMonitoring {
            HStack(spacing: 0) {
                statPill(
                    icon: "figure.stand",
                    label: "Score",
                    value: "\(viewModel.postureScore)",
                    color: scoreColor
                )
                Divider().frame(height: 30)
                statPill(
                    icon: "arrow.clockwise",
                    label: "Recovery",
                    value: "\(viewModel.recoverySessions)",
                    color: .brandAccent
                )
                Divider().frame(height: 30)
                statPill(
                    icon: "clock",
                    label: "Last check",
                    value: viewModel.lastCheckText,
                    color: .brandPrimary
                )
            }
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(duration: 0.3), value: viewModel.isMonitoring)
        }
    }

    private func statPill(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var scoreColor: Color {
        switch viewModel.postureScore {
        case 80...100: return .statusSuccess
        case 60..<80:  return .statusWarning
        default:       return .statusError
        }
    }

    // MARK: — Action Rows

    private var actionRows: some View {
        VStack(spacing: 0) {
            // Open Dashboard
            menuRow(
                icon: "square.grid.2x2.fill",
                label: "Open Dashboard",
                subtitle: "View your wellness stats"
            ) {
                openWindow(id: AppWindowID.dashboard)
            }

            Divider().padding(.leading, 44)

            // Camera Debug
            menuRow(
                icon: "camera.viewfinder",
                label: "Camera Debug",
                subtitle: "Live preview & diagnostics",
                iconColor: .brandAccent
            ) {
                openWindow(id: AppWindowID.cameraDebug)
            }

            Divider().padding(.leading, 44)

            // Start / Stop Monitoring (toggling)
            if viewModel.isMonitoring {
                menuRow(
                    icon: "stop.circle.fill",
                    label: "Stop Monitoring",
                    subtitle: "Pause posture detection",
                    iconColor: .statusError
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.stopMonitoring()
                    }
                }
            } else {
                menuRow(
                    icon: "play.circle.fill",
                    label: "Start Monitoring",
                    subtitle: "Begin posture detection",
                    iconColor: .statusSuccess
                ) {
                    if viewModel.isCalibrated {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.startMonitoring()
                        }
                    } else {
                        // Open the main dashboard window to show the calibration sheet
                        openWindow(id: AppWindowID.dashboard)
                    }
                }
            }

            Divider().padding(.leading, 44)

            // Settings
            menuRow(
                icon: "gearshape.fill",
                label: "Settings",
                subtitle: "Configure DeskReset",
                shortcut: "⌘,"
            ) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Divider()

            // Quit
            menuRow(
                icon: "power",
                label: "Quit DeskReset",
                isDestructive: true
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    // MARK: — Row Builder

    private func menuRow(
        icon: String,
        label: String,
        subtitle: String? = nil,
        iconColor: Color? = nil,
        shortcut: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(
                        isDestructive ? Color.statusError :
                        (iconColor ?? .brandPrimary)
                    )

                // Label + subtitle
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(isDestructive ? Color.statusError : Color.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Spacer()

                // Shortcut hint
                if let shortcut {
                    Text(shortcut)
                        .font(.caption2)
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight()
    }
}

// MARK: — Hover highlight modifier

private struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                isHovered
                    ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12)
                    : Color.clear
            )
            .onHover { isHovered = $0 }
            .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

private extension View {
    func hoverHighlight() -> some View {
        modifier(HoverHighlightModifier())
    }
}

#Preview {
    MenuBarView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService(),
            cameraService: CameraService()
        ))
}
