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
    }

    // MARK: — Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App brand header
            sidebarHeader

            Divider()

            // Nav items
            List(SidebarItem.allCases, selection: $selectedSidebar) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
                    .padding(.vertical, 2)
            }
            .listStyle(.sidebar)

            Spacer(minLength: 0)

            Divider()

            // Monitoring control at bottom of sidebar
            sidebarMonitoringControl
        }
        .navigationSplitViewColumnWidth(min: 170, ideal: 190)
        .toolbar(removing: .sidebarToggle)
    }

    private var sidebarHeader: some View {
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
        VStack(spacing: 10) {
            // State indicator row
            HStack(spacing: 7) {
                Circle()
                    .fill(viewModel.monitoringState == .active ? Color.statusSuccess : Color(nsColor: .systemGray))
                    .frame(width: 7, height: 7)
                    .shadow(
                        color: viewModel.monitoringState == .active ? Color.statusSuccess.opacity(0.6) : .clear,
                        radius: 3
                    )
                Text(viewModel.monitoringState.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text(viewModel.monitoringUptime)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.textTertiary)
            }

            // Toggle button
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
                    Text(viewModel.monitoringState == .active ? "Stop" : "Start Monitoring")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.monitoringState == .active ? .statusError : .brandPrimary)
            .controlSize(.small)
            .animation(.easeInOut(duration: 0.2), value: viewModel.monitoringState)

            // Posture chip
            HStack(spacing: 5) {
                Image(systemName: "camera.viewfinder")
                    .font(.caption2)
                Text("Posture Detection — Coming Soon")
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
            VStack(alignment: .leading, spacing: 28) {
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
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            .controlSize(.regular)
        }
        .padding(14)
        .background(.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.brandPrimary.opacity(0.25), lineWidth: 1)
        )
    }

    // Page title + greeting
    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Good \(timeOfDayGreeting()) 👋")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            // Refresh button
            Button {
                viewModel.loadStats(modelContext: modelContext)
                viewModel.refreshMonitoringState()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh dashboard")
        }
    }

    // MARK: — 5 Placeholder Cards Grid

    private var cardGrid: some View {
        VStack(spacing: 14) {
            // Row 1: three equal cards
            HStack(spacing: 14) {
                // Card 1 — Current Status
                DashboardCardView(
                    id: .currentStatus,
                    title: "Current Status",
                    icon: viewModel.currentStatusIcon,
                    accentColor: statusAccentColor,
                    style: .status,
                    isSelected: viewModel.selectedCardID == .currentStatus,
                    primaryValue: viewModel.currentStatus,
                    secondaryLabel: viewModel.currentStatusDetail,
                    badge: viewModel.monitoringState.rawValue,
                    badgeColor: badgeColorForState,
                    isPlaceholder: viewModel.monitoringState == .inactive
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .currentStatus ? nil : .currentStatus
                }

                // Card 2 — Today's Score
                DashboardCardView(
                    id: .todayScore,
                    title: "Today's Score",
                    icon: "chart.bar.fill",
                    accentColor: scoreAccentColor,
                    style: .progress,
                    isSelected: viewModel.selectedCardID == .todayScore,
                    primaryValue: viewModel.todayScore == 0 ? "—" : "\(viewModel.todayScore)",
                    secondaryLabel: viewModel.todayScore == 0 ? "Start monitoring" : viewModel.todayScoreLabel,
                    progress: viewModel.todayScoreProgress,
                    isPlaceholder: viewModel.todayScore == 0
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .todayScore ? nil : .todayScore
                }

                // Card 3 — Monitoring State
                DashboardCardView(
                    id: .monitoringState,
                    title: "Monitoring State",
                    icon: viewModel.monitoringState.icon,
                    accentColor: monitoringAccentColor,
                    style: .standard,
                    isSelected: viewModel.selectedCardID == .monitoringState,
                    primaryValue: viewModel.monitoringState.rawValue,
                    secondaryLabel: viewModel.monitoringState == .active
                        ? "Running for \(viewModel.monitoringUptime)"
                        : "Tap sidebar to start",
                    isPlaceholder: viewModel.monitoringState == .inactive
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .monitoringState ? nil : .monitoringState
                }
            }
            .frame(height: 150)

            // Row 2: two wider cards
            HStack(spacing: 14) {
                // Card 4 — Recovery Sessions
                DashboardCardView(
                    id: .recoverySessions,
                    title: "Recovery Sessions",
                    icon: "figure.walk.circle.fill",
                    accentColor: .teal,
                    style: .progress,
                    isSelected: viewModel.selectedCardID == .recoverySessions,
                    primaryValue: "\(viewModel.recoverySessions)",
                    secondaryLabel: viewModel.recoverySessions == 0
                        ? "No sessions yet today"
                        : "Last: \(viewModel.lastRecovery)",
                    progress: viewModel.recoveryProgress,
                    isPlaceholder: viewModel.recoverySessions == 0
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .recoverySessions ? nil : .recoverySessions
                }

                // Card 5 — Last Check Time
                DashboardCardView(
                    id: .lastCheckTime,
                    title: "Last Check Time",
                    icon: "clock.badge.checkmark.fill",
                    accentColor: .orange,
                    style: .timeline,
                    isSelected: viewModel.selectedCardID == .lastCheckTime,
                    primaryValue: viewModel.lastCheckDisplay,
                    primaryLabel: viewModel.lastCheckTime != nil
                        ? "Next check in \(viewModel.nextCheckIn)"
                        : nil,
                    secondaryLabel: viewModel.totalChecks > 0
                        ? "\(viewModel.totalChecks) total check\(viewModel.totalChecks == 1 ? "" : "s") today"
                        : "Waiting for first check",
                    isPlaceholder: viewModel.lastCheckTime == nil
                ) {
                    viewModel.selectedCardID = viewModel.selectedCardID == .lastCheckTime ? nil : .lastCheckTime
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: — Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Quick recovery break action with generated structured routine
            Button {
                Task {
                    let assessment = serviceLocator.postureService.currentAssessment ?? PostureAssessment()
                    let routine = await serviceLocator.ergonomicAdvisorService.generateRoutine(for: assessment)
                    activeRoutine = routine
                }
            } label: {
                Label("Take Recovery Break", systemImage: "figure.walk")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPrimary)
            .controlSize(.large)

            // Calibrate posture button
            Button {
                showCalibrationSheet = true
            } label: {
                Label("Calibrate Posture", systemImage: "figure.stand")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            // History shortcut
            Button {
                selectedSidebar = .history
            } label: {
                Label("View History", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
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

    // MARK: — Background

    private var dashboardBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            // Subtle gradient orbs for depth
            Circle()
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.06 : 0.04))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -80, y: -80)
            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.05 : 0.03))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 200, y: 120)
        }
        .ignoresSafeArea()
    }

    // MARK: — Derived Colors

    private var statusAccentColor: Color {
        switch viewModel.monitoringState {
        case .active:   return .statusSuccess
        case .paused:   return .statusWarning
        case .inactive: return .brandPrimary
        }
    }

    private var scoreAccentColor: Color {
        switch viewModel.todayScore {
        case 80...100: return .statusSuccess
        case 60..<80:  return .statusWarning
        case 1..<60:   return .statusError
        default:       return .brandAccent
        }
    }

    private var monitoringAccentColor: Color {
        viewModel.monitoringState == .active ? .statusSuccess : Color(nsColor: .systemGray)
    }

    private var badgeColorForState: Color {
        switch viewModel.monitoringState {
        case .active:   return .statusSuccess
        case .paused:   return .statusWarning
        case .inactive: return Color(nsColor: .systemGray)
        }
    }

    // MARK: — Helpers

    private func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default:      return "Night"
        }
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
