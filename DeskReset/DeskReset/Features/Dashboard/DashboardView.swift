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
    @Environment(\.openWindow) private var openWindow

    @State private var viewModel = DashboardViewModel()
    @State private var selectedSidebar: SidebarItem = .overview
    @State private var showCalibrationSheet: Bool        = false
    @State private var showRoutineSheet: Bool            = false
    @State private var activeRoutine: ErgonomicRecoveryRoutine? = nil
    @State private var isCameraCardHovered: Bool         = false
    @State private var showDailySummaryDetail: Bool      = false
    @State private var showPostureDetail: Bool           = false

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
        Group {
            if viewModel.showOnboarding {
                PostureOnboardingView {
                    withAnimation(.spring(duration: 0.5)) {
                        viewModel.completeOnboarding()
                    }
                }
                .environment(serviceLocator)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            } else {
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    sidebar
                } detail: {
                    detailPane
                        // Enforce a hard min so sidebar can NEVER push detail off screen
                        .frame(minWidth: 540, maxWidth: .infinity, minHeight: 440)
                }
                // .prominentDetail keeps detail pane dominant; sidebar can't eat into its space
                .navigationSplitViewStyle(.prominentDetail)
                .frame(minWidth: 760, idealWidth: 960, maxWidth: 1400, minHeight: 490)
                .onAppear {
                    viewModel.configure(with: serviceLocator)
                    viewModel.loadStats(modelContext: modelContext)
                }
            }
        }
        .animation(.spring(duration: 0.5), value: viewModel.showOnboarding)
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
        // Sidebar: 160 min so text is always legible; 220 max so it never dominates
        .navigationSplitViewColumnWidth(min: 160, ideal: 195, max: 220)
        .toolbar(removing: .sidebarToggle)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brandPrimary)
                    .frame(width: 30, height: 30)
                Image(systemName: "figure.walk")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            // Use fixedSize(false) so text truncates inside the column rather than overflows
            VStack(alignment: .leading, spacing: 0) {
                Text("DeskReset")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Wellness Hub")
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if viewModel.monitoringState == .active {
                    Text("· \(viewModel.monitoringUptime)")
                        .font(.system(size: 11.5, weight: .medium).monospacedDigit())
                        .foregroundStyle(.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
            }

            // Toggle button (Frosted Glass Style with Pure White Text)
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if viewModel.monitoringState == .active {
                        viewModel.stopMonitoring()
                    } else {
                        viewModel.startMonitoring()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.monitoringState == .active ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.buttonIconAccent)
                    Text(viewModel.monitoringState == .active ? "Stop" : "Start Monitoring")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            viewModel.monitoringState == .active
                                ? Color.statusError
                                : Color.brandPrimary
                        )
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
        // Daily Summary detail sheet
        .sheet(isPresented: $showDailySummaryDetail) {
            DailySummaryDetailView(
                score:            viewModel.todayScore,
                scoreLabel:       viewModel.todayScoreLabel,
                breaksDone:       viewModel.recoverySessions,
                breakGoal:        viewModel.recoveryGoal,
                monitoringUptime: viewModel.monitoringUptime,
                topIssue:         viewModel.topPostureIssue,
                topIssueIcon:     viewModel.topPostureIssueIcon,
                motivationalTip:  viewModel.motivationalTip,
                isMonitoring:     viewModel.monitoringState == .active
            )
        }
        // Current Posture detail sheet
        .sheet(isPresented: $showPostureDetail) {
            PostureDetailSheet(
                monitoringState:  viewModel.monitoringState,
                currentStatus:    viewModel.currentStatus,
                currentDetail:    viewModel.currentStatusDetail,
                todayScore:       viewModel.todayScore,
                totalChecks:      viewModel.totalChecks,
                topIssue:         viewModel.topPostureIssue,
                topIssueIcon:     viewModel.topPostureIssueIcon
            )
        }
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
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .foregroundStyle(Color.buttonIconAccent)
                    Text("Calibrate Now")
                        .foregroundStyle(Color.white)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brandPrimary)
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
                    .foregroundStyle(Color.buttonIconAccent)
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

    // MARK: — Two-Column Card Grid (Equal height, pixel-perfect alignment)

    private let cardHeight: CGFloat = 162

    private var cardGrid: some View {
        HStack(alignment: .top, spacing: 14) {

            // ── LEFT COLUMN ──────────────────────────────────────────
            VStack(spacing: 14) {
                // Card 1 — Current Posture Status (tappable → PostureDetailSheet)
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
                    showPostureDetail = true
                    viewModel.selectedCardID = viewModel.selectedCardID == .currentStatus ? nil : .currentStatus
                }
                .frame(height: cardHeight)

                // Card 2 — Live Vision AI Guidance
                liveCameraGuidanceCard
                    .frame(height: cardHeight)
            }
            .frame(maxWidth: .infinity)

            // ── RIGHT COLUMN ─────────────────────────────────────────
            VStack(spacing: 14) {
                // Card 3 — Daily Wellness Summary (tappable → detail sheet)
                Button {
                    showDailySummaryDetail = true
                } label: {
                    DashboardDailySummaryCardView(
                        score:            viewModel.todayScore,
                        scoreLabel:       viewModel.todayScoreLabel,
                        breaksDone:       viewModel.recoverySessions,
                        breakGoal:        viewModel.recoveryGoal,
                        monitoringUptime: viewModel.monitoringUptime,
                        topIssue:         viewModel.topPostureIssue,
                        topIssueIcon:     viewModel.topPostureIssueIcon,
                        motivationalTip:  viewModel.motivationalTip,
                        isMonitoring:     viewModel.monitoringState == .active
                    )
                }
                .buttonStyle(.plain)
                .frame(height: cardHeight)
                .help("Tap to view detailed daily summary")

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
                    secondaryLabel: viewModel.totalChecks > 0
                        ? "\(viewModel.totalChecks) check\(viewModel.totalChecks == 1 ? "" : "s") recorded today"
                        : "Waiting for first check interval"
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .lastCheckTime ? nil : .lastCheckTime
                }
                .frame(height: cardHeight)
            }
            .frame(maxWidth: .infinity)
        }
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

    private var liveCameraGuidanceCard: some View {
        LiveCameraGuidanceCardView(
            monitoringState: viewModel.monitoringState,
            cameraService: serviceLocator.cameraService
        ) {
            openWindow(id: AppWindowID.cameraDebug)
        }
    }
}

// MARK: — Live Camera Guidance Card View

struct LiveCameraGuidanceCardView: View {
    let monitoringState: MonitoringState
    let cameraService: CameraServiceProtocol?
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Header Row
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.drIconTileBackground)
                            .frame(width: 32, height: 32)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.buttonIconAccent)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Vision AI Guidance")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Tap card to open Camera Debug")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(monitoringState == .active ? Color.brandSecondary : Color.textTertiary)
                            .frame(width: 6, height: 6)
                        Text(monitoringState == .active ? "LIVE" : "STANDBY")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(monitoringState == .active ? Color.brandSecondary : Color.textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.brandSecondary.opacity(0.14), in: Capsule())
                }

                // Mini Camera Preview Box
                ZStack {
                    if let cameraService = cameraService,
                       cameraService.isRunning {
                        CameraPreviewView(session: cameraService.captureSession)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.drInnerBoxBackground)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(Color.buttonIconAccent)
                                    Text("Vision AI Standby · Tap to Preview")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.textSecondary)
                                }
                            )
                    }

                    // Hover / Overlay Debug Badge
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 9, weight: .bold))
                                Text("CAMERA DEBUG")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color.brandPrimary, in: Capsule())
                            .shadow(color: Color.brandPrimary.opacity(0.4), radius: 4)
                        }
                        Spacer()
                    }
                    .padding(6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isHovered ? Color.brandAccent : Color.drGlassSpecularBorder, lineWidth: 1)
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isHovered ? Color.brandPrimary.opacity(0.06) : Color.drCardBackground)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isHovered ? Color.brandAccent : Color.drGlassSpecularBorder,
                        lineWidth: isHovered ? 1.5 : 1.0
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
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
                    .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.buttonIconAccent : (isHovered ? Color.buttonIconAccent : Color.textSecondary))
                    .frame(width: 18)  // Fixed width so icon never shifts text

                Text(item.rawValue)
                    .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.textSecondary))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.brandPrimary)
                    .shadow(color: Color.brandPrimary.opacity(0.35), radius: 6, x: 0, y: 2)
            } else if isHovered {
                Capsule()
                    .fill(Color.brandPrimary.opacity(0.15))
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.buttonIconAccent)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isHovered ? Color.brandPrimary : Color.brandPrimary.opacity(0.85))
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

private struct DashboardDailySummaryCardView: View {

    let score: Int
    let scoreLabel: String
    let breaksDone: Int
    let breakGoal: Int
    let monitoringUptime: String
    let topIssue: String?
    let topIssueIcon: String?
    let motivationalTip: String
    let isMonitoring: Bool

    @State private var isHovered      = false
    @State private var ringTrim       = 0.0      // animated 0 → scoreProgress
    @State private var barWidth       = 0.0      // animated 0 → breakProgress
    @State private var pulseOpacity   = 1.0      // live dot pulse
    @State private var shimmerOffset  = -80.0    // shimmer on ring

    private var scoreProgress: Double { Double(score) / 100.0 }
    private var breakProgress: Double { breakGoal > 0 ? min(Double(breaksDone) / Double(breakGoal), 1.0) : 0 }
    private var accentColor: Color    { Color.postureScoreColor(for: score) }
    private var gradientStroke: LinearGradient {
        LinearGradient(colors: [accentColor.opacity(0.7), accentColor],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 18)
                .fill(isHovered ? Color.brandPrimary.opacity(0.07) : Color.drCardBackground)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

            // Border
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isHovered
                        ? LinearGradient(colors: [Color.brandPrimary.opacity(0.7), Color.brandSecondary.opacity(0.5)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.drGlassSpecularBorder],
                                         startPoint: .top, endPoint: .bottom),
                    lineWidth: isHovered ? 1.5 : 1.0
                )

            // Content
            VStack(alignment: .leading, spacing: 0) {
                headerRow

                HStack(alignment: .center, spacing: 12) {
                    scoreRing
                    statsColumn
                }
                .padding(.top, 9)

                Spacer(minLength: 4)
                breakProgressBar
                Spacer(minLength: 6)
                motivationalFooter
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .shadow(
            color: isHovered ? Color.brandPrimary.opacity(0.18) : Color.black.opacity(0.07),
            radius: isHovered ? 10 : 4, y: 2
        )
        .scaleEffect(isHovered ? 1.012 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.18), value: isHovered)
        .onAppear {
            // Staggered entrance
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.15)) {
                ringTrim = scoreProgress
            }
            withAnimation(.easeInOut(duration: 0.75).delay(0.35)) {
                barWidth = breakProgress
            }
            // Live dot pulse
            if isMonitoring {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.3
                }
            }
            // Shimmer sweep
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false).delay(0.6)) {
                shimmerOffset = 120
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                ringTrim = scoreProgress
            }
        }
        .onChange(of: breaksDone) { _, _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                barWidth = breakProgress
            }
        }
    }

    // MARK: — Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.drIconTileBackground)
                    .frame(width: 32, height: 32)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text("Daily Summary")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(.textPrimary)

            Spacer()

            if isMonitoring {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.statusSuccess)
                        .frame(width: 6, height: 6)
                        .opacity(pulseOpacity)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.statusSuccess)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.statusSuccess.opacity(0.11), in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(isHovered ? Color.brandPrimary : Color.textTertiary)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
    }

    // MARK: — Score Ring (animated + shimmer)

    private var scoreRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(accentColor.opacity(0.14), lineWidth: 6)

            // Animated fill arc
            Circle()
                .trim(from: 0, to: ringTrim)
                .stroke(
                    AngularGradient(
                        colors: [accentColor.opacity(0.6), accentColor, accentColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Shimmer overlay on the ring
            Circle()
                .trim(from: 0, to: ringTrim)
                .stroke(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90 + shimmerOffset))

            // Center text
            VStack(spacing: 0) {
                Text(score == 0 ? "–" : "\(score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())
                if score > 0 {
                    Text(scoreLabel)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(width: 60, height: 60)
    }

    // MARK: — Stats Column

    private var statsColumn: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label {
                Text(monitoringUptime == "—" ? "Not monitoring" : "\(monitoringUptime) active")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.textSecondary)
            } icon: {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }

            Label {
                Text("\(breaksDone)/\(breakGoal) breaks")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.textSecondary)
            } icon: {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.statusSuccess)
            }

            if let issue = topIssue, let icon = topIssueIcon {
                HStack(spacing: 3) {
                    Image(systemName: icon).font(.system(size: 8.5, weight: .bold))
                    Text(issue).font(.system(size: 9, weight: .bold)).lineLimit(1).truncationMode(.tail)
                }
                .foregroundStyle(Color.statusWarning)
                .padding(.horizontal, 6).padding(.vertical, 2.5)
                .background(Color.statusWarning.opacity(0.12), in: Capsule())
            } else if score > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 8.5, weight: .bold))
                    Text("No issues").font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Color.statusSuccess)
                .padding(.horizontal, 6).padding(.vertical, 2.5)
                .background(Color.statusSuccess.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: — Break Progress Bar (animated gradient)

    private var breakProgressBar: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Break Goal")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("\(breaksDone) of \(breakGoal)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.brandPrimary.opacity(0.10))
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: breakProgress >= 1.0
                                    ? [Color.statusSuccess.opacity(0.8), Color.statusSuccess]
                                    : [Color.brandPrimary.opacity(0.8), Color.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * barWidth, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: — Motivational Footer

    private var motivationalFooter: some View {
        HStack(spacing: 5) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(Color.statusWarning)
            Text(motivationalTip)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.statusWarning.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
    }
}

// DashboardPostureOnboardingView removed — replaced by PostureOnboardingView (PostureOnboardingView.swift)
// which now features AI-generated hero images and animated slide transitions.


#Preview {
    DashboardView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService()
        ))
}
