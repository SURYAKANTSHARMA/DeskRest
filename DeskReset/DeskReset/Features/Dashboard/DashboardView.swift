//
//  DashboardView.swift
//  DeskReset
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = DashboardViewModel()
    @State private var selectedSidebar: SidebarItem = .overview
    @State private var showCalibrationSheet: Bool   = false
    @State private var showRoutineSheet: Bool       = false
    @State private var activeRoutine: ErgonomicRecoveryRoutine? = nil

    // MARK: — Sidebar Items

    enum SidebarItem: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case history  = "History"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2.fill"
            case .history:  return "clock.arrow.circlepath"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } detail: {
            detailPane
                .frame(minWidth: 600, minHeight: 440)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 780, minHeight: 490)
        .onAppear {
            viewModel.configure(with: serviceLocator)
            viewModel.loadStats(modelContext: modelContext)
        }
        .onChange(of: serviceLocator.postureService.nextCheckTime) { _, _ in
            viewModel.loadStats(modelContext: modelContext)
        }
    }

    // MARK: — Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            Divider()

            // Nav items (Custom glassmorphism sidebar buttons)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarButton(
                        item: item,
                        isSelected: selectedSidebar == item
                    ) {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedSidebar = item
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)

            Spacer(minLength: 0)

            Divider()

            // Monitoring control at bottom of sidebar
            sidebarMonitoringControl
        }
        .background(Color.drCardBackground)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1),
            alignment: .trailing
        )
        .navigationSplitViewColumnWidth(min: 170, ideal: 190)
        .toolbar(removing: .sidebarToggle)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary, .brandSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: "figure.walk")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("DeskReset")
                    .font(.headline)
                Text("Wellness Hub")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var sidebarMonitoringControl: some View {
        VStack(spacing: 12) {
            // Centered & larger State indicator row
            HStack(spacing: 8) {
                Spacer()
                Circle()
                    .fill(viewModel.monitoringState == .active ? Color.brandSecondary : Color.textTertiary)
                    .frame(width: 8, height: 8)
                    .shadow(
                        color: viewModel.monitoringState == .active ? Color.brandSecondary.opacity(0.8) : .clear,
                        radius: 5
                    )
                Text(viewModel.monitoringState.rawValue)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(.textPrimary)

                if viewModel.monitoringState == .active {
                    Text("· \(viewModel.monitoringUptime)")
                        .font(.system(size: 12.5, weight: .medium).monospacedDigit())
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
            }

            // Toggle button (Frosted Glass Style with Pure White Text)
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if viewModel.monitoringState == .active {
                        viewModel.stopMonitoring()
                    } else {
                        if viewModel.isCalibrated {
                            viewModel.startMonitoring()
                        } else {
                            showCalibrationSheet = true
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.monitoringState == .active ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(viewModel.monitoringState == .active ? "Stop Monitoring" : "Start Monitoring")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.white) // Crisp White text & icon!
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            viewModel.monitoringState == .active
                                ? LinearGradient(colors: [Color.statusError.opacity(0.85), Color.statusError.opacity(0.65)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.brandPrimary.opacity(0.88), Color.brandSecondary.opacity(0.78)], startPoint: .leading, endPoint: .trailing)
                        )
                        .background(.ultraThinMaterial, in: Capsule())
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            viewModel.monitoringState == .active
                                ? AnyShapeStyle(Color.statusError.opacity(0.8))
                                : AnyShapeStyle(Color.drGlassSpecularBorder),
                            lineWidth: 1.2
                        )
                )
                .shadow(
                    color: viewModel.monitoringState == .active
                        ? Color.statusError.opacity(0.4)
                        : Color.brandPrimary.opacity(0.45),
                    radius: 8,
                    x: 0,
                    y: 3
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.monitoringState)

            // Posture chip
            HStack(spacing: 5) {
                Image(systemName: "camera.viewfinder")
                    .font(.caption2)
                Text("Posture Detection — Active")
                    .font(.caption2)
            }
            .foregroundStyle(.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: — Detail Pane

    @ViewBuilder
    private var detailPane: some View {
        switch selectedSidebar {
        case .overview: overviewContent
        case .history:  historyContent
        }
    }

    // MARK: — Overview

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader
                if !viewModel.isCalibrated {
                    calibrationBanner
                }
                cardGrid
                actionBar
            }
            .padding(26)
        }
        .background(dashboardBackground)
        .sheet(isPresented: $showCalibrationSheet) {
            CalibrationView()
                .environment(serviceLocator)
                .onDisappear {
                    viewModel.loadStats(modelContext: modelContext)
                }
        }
        .sheet(item: $activeRoutine) { routine in
            RecoveryRoutineView(routine: routine) {
                Task {
                    await viewModel.takeBreakNow()
                    viewModel.loadStats(modelContext: modelContext)
                }
            }
        }
    }

    // Calibration Prompt Banner
    private var calibrationBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.stand")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Posture Baseline Required")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Text("Take 10 seconds to calibrate your posture baseline for accurate monitoring.")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            Button {
                showCalibrationSheet = true
            } label: {
                Label("Calibrate Now", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.brandPrimary.opacity(0.2))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.brandPrimary, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1)
        )
    }

    // Page title + formatted date
    private var pageHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 8) {
                Text("Dashboard")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text("·")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.textTertiary)
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            // Glassmorphic Refresh button
            Button {
                viewModel.loadStats(modelContext: modelContext)
                viewModel.refreshMonitoringState()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)
                    .padding(7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.drCardBackground)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh dashboard")
        }
    }

    // MARK: — Two-Column Track Restructure (Consistent Card Heights)

    private var cardGrid: some View {
        HStack(alignment: .top, spacing: 14) {
            // LEFT COLUMN: Posture Tracker Track
            VStack(spacing: 14) {
                // Card 1 — Current Posture Status
                DashboardCardView(
                    id: .currentStatus,
                    title: "Current Posture",
                    icon: "figure.stand",
                    accentColor: statusAccentColor,
                    style: .status,
                    isSelected: viewModel.selectedCardID == .currentStatus,
                    primaryValue: viewModel.currentStatus,
                    secondaryLabel: viewModel.currentStatusDetail,
                    badge: viewModel.monitoringState.rawValue,
                    badgeColor: badgeColorForState
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .currentStatus ? nil : .currentStatus
                }
                .frame(height: 160)

                // Card 2 — Live Vision AI Guidance
                liveCameraGuidanceCard
                    .frame(height: 160)
            }

            // RIGHT COLUMN: Wellness Stats Track
            VStack(spacing: 14) {
                // Card 3 — Daily Wellness Summary (Score + Breaks)
                DashboardCardView(
                    id: .todayScore,
                    title: "Daily Score Summary",
                    icon: "chart.bar.fill",
                    accentColor: scoreAccentColor,
                    style: .progress,
                    isSelected: viewModel.selectedCardID == .todayScore,
                    primaryValue: viewModel.todayScore == 0 ? "—" : "\(viewModel.todayScore)",
                    secondaryLabel: viewModel.todayScore == 0 ? "Start monitoring to track" : "\(viewModel.todayScoreLabel) · \(viewModel.recoverySessions) breaks done",
                    progress: viewModel.todayScoreProgress
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .todayScore ? nil : .todayScore
                }
                .frame(height: 160)

                // Card 4 — Consistency / Last Check Time
                DashboardCardView(
                    id: .lastCheckTime,
                    title: "Consistency",
                    icon: "clock.badge.checkmark.fill",
                    accentColor: .brandAccent,
                    style: .timeline,
                    isSelected: viewModel.selectedCardID == .lastCheckTime,
                    primaryValue: viewModel.lastCheckDisplay,
                    primaryLabel: viewModel.lastCheckTime != nil
                        ? "Next check in \(viewModel.nextCheckIn)"
                        : nil,
                    secondaryLabel: viewModel.lastScanFeedback
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .lastCheckTime ? nil : .lastCheckTime
                }
                .frame(height: 160)
            }
        }
    }

    // MARK: — Live Camera Guidance (Consistent 160pt Height)
    private var liveCameraGuidanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.drIconTileBackground)
                        .frame(width: 36, height: 36)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.brandSecondary)
                }
                Text("Vision AI Guidance")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.monitoringState == .active ? Color.brandSecondary : Color.textTertiary)
                        .frame(width: 6, height: 6)
                    Text(viewModel.monitoringState == .active ? "ACTIVE" : "STANDBY")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(viewModel.monitoringState == .active ? Color.brandSecondary : Color.textTertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Color.brandSecondary.opacity(0.14), in: Capsule())
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.brandSecondary.opacity(0.25), lineWidth: 1)
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.brandSecondary)
                        .shadow(color: Color.brandSecondary.opacity(0.6), radius: 6)
                }
                Text(
                    viewModel.monitoringState == .active
                        ? "Vision AI actively monitoring posture baseline"
                        : "Start monitoring to activate Vision AI posture guidance"
                )
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(Color.drInnerBoxBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.drCardBackground)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1.0)
        )
    }

    // MARK: — Action Bar (Hollow Glass Buttons: Cyan text, Purple outline)

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Take Recovery Break
            HollowActionButton(
                title: "Take Recovery Break",
                icon: "figure.walk"
            ) {
                Task {
                    let assessment = serviceLocator.postureService.currentAssessment ?? PostureAssessment()
                    let routine = await serviceLocator.ergonomicAdvisorService.generateRoutine(for: assessment)
                    activeRoutine = routine
                }
            }

            // Calibrate Posture
            HollowActionButton(
                title: "Calibrate Posture",
                icon: "figure.stand"
            ) {
                showCalibrationSheet = true
            }
        }
    }

    // MARK: — History Tab

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery History")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(viewModel.recentSessions.count) sessions recorded")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                BreakHistoryView(sessions: viewModel.recentSessions)
            }
            .padding(26)
        }
        .background(dashboardBackground)
    }

    // MARK: — Background (Vibrant Glowing Cosmic Orbs for Glassmorphism)

    private var dashboardBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            // Purple cosmic orb
            Circle()
                .fill(Color.brandPrimary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
                .offset(x: -120, y: -100)
            // Cyan aurora orb
            Circle()
                .fill(Color.brandSecondary.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 220, y: 140)
        }
        .ignoresSafeArea()
    }

    // MARK: — Derived Colors

    private var statusAccentColor: Color {
        switch viewModel.monitoringState {
        case .active:   return .brandSecondary
        case .paused:   return .statusWarning
        case .inactive: return .brandPrimary
        }
    }

    private var scoreAccentColor: Color {
        Color.postureScoreColor(for: viewModel.todayScore)
    }

    private var badgeColorForState: Color {
        switch viewModel.monitoringState {
        case .active:   return .brandSecondary
        case .paused:   return .statusWarning
        case .inactive: return Color(nsColor: .systemGray)
        }
    }
}

// MARK: — Sidebar Button (Frosted Glass Capsule + Pure White Text)

struct SidebarButton: View {
    let item: DashboardView.SidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.textSecondary))

                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.textSecondary))

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9.5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.88),
                                Color.brandSecondary.opacity(0.78)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1.2)
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.45), radius: 8, x: 0, y: 3)
            } else if isHovered {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.30),
                                Color.brandSecondary.opacity(0.18)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1.0)
                    )
                    .shadow(color: Color.brandPrimary.opacity(0.20), radius: 6, x: 0, y: 2)
            }
        }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: — Hollow Action Button (Frosted Glass + Cyan Text + Purple Outline)

struct HollowActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white) // Crisp Pure White text & icon!
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isHovered
                                ? LinearGradient(colors: [Color.brandPrimary.opacity(0.85), Color.brandSecondary.opacity(0.75)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.brandPrimary.opacity(0.35), Color.brandSecondary.opacity(0.20)], startPoint: .leading, endPoint: .trailing)
                        )
                        .background(.ultraThinMaterial, in: Capsule())
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isHovered
                                ? AnyShapeStyle(Color.brandSecondary)
                                : AnyShapeStyle(Color.drGlassSpecularBorder),
                            lineWidth: 1.2
                        )
                )
                .shadow(
                    color: Color.brandPrimary.opacity(isHovered ? 0.50 : 0.25),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    DashboardView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService()
        ))
}
