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
    @State private var showCalibrationSheet: Bool = false

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
        .onChange(of: serviceLocator.postureService.nextCheckTime) { _, _ in
            viewModel.loadStats(modelContext: modelContext)
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
            // App icon — rendered at full size, its own squircle shape shows naturally
            Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .shadow(color: Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.4), radius: 4, y: 2)

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
                        if viewModel.isCalibrated {
                            viewModel.startMonitoring()
                        } else {
                            showCalibrationSheet = true
                        }
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
                    .foregroundStyle(Color.brandSecondary)
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
        VStack(spacing: 0) {

            // ── Fixed header ─────────────────────────────────────────────
            // Sits completely outside the scroll context so it can NEVER
            // overlap cards or the suggestions panel.
            pageHeader
                .padding(.horizontal, 26)
                .padding(.top, 18)
                .padding(.bottom, 14)

            Divider().opacity(0.25)

            // ── Scrollable body ──────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.isCalibrated {
                        calibrationBanner
                    }
                    cardGrid
                    postureAdvisorPanel
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 20)
            }
        }
        .sheet(isPresented: $showCalibrationSheet) {
            CalibrationView()
                .environment(serviceLocator)
                .onDisappear {
                    viewModel.loadStats(modelContext: modelContext)
                }
        }
    }

    // Calibration Prompt Banner
    private var calibrationBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandSecondary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.stand")
                    .font(.title3)
                    .foregroundStyle(Color.brandSecondary)
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

    // Page title + formatted date + Live Status Badge & Next check subtitle
    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text("Dashboard")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.textPrimary)
                
                liveStatusBadge
                
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
            
            // Subtitle: plain HStack with concise chip labels — no scroll, no frame collapse
            HStack(spacing: 6) {
                statusChip(
                    icon: "calendar",
                    text: Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)),
                    color: .brandPrimary
                )
                
                if viewModel.monitoringState == .active {
                    statusChip(
                        icon: "stopwatch",
                        text: "Next: \(viewModel.nextCheckIn.replacingOccurrences(of: "in ", with: ""))",
                        color: .brandSecondary
                    )
                }
                
                statusChip(
                    icon: "timer",
                    text: "Active: \(viewModel.monitoringUptime == "—" ? "0m" : viewModel.monitoringUptime)",
                    color: .brandSecondary
                )
                
                statusChip(
                    icon: "checkmark.circle",
                    text: "\(viewModel.todayScansCount) scanned",
                    color: .statusSuccess
                )
                
                if viewModel.todayAwayCount > 0 {
                    statusChip(
                        icon: "person.slash",
                        text: "\(viewModel.todayAwayCount) away",
                        color: .statusWarning
                    )
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    private func statusChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            
            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(color.opacity(colorScheme == .dark ? 0.08 : 0.05))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(color.opacity(colorScheme == .dark ? 0.22 : 0.15), lineWidth: 1)
        )
    }

    private var liveStatusBadge: some View {
        Group {
            switch viewModel.monitoringState {
            case .active:
                if serviceLocator.postureService.lastRunStatus == .personNotDetected {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Away from Desk")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.statusWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusWarning.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.statusWarning.opacity(0.3), lineWidth: 1))
                } else if viewModel.todayScore >= 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Good Posture (\(viewModel.todayScore))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.statusSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusSuccess.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.statusSuccess.opacity(0.3), lineWidth: 1))
                } else if viewModel.todayScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Needs Adjustment (\(viewModel.todayScore))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.statusError)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusError.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.statusError.opacity(0.3), lineWidth: 1))
                } else {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: 10, height: 10)
                        Text("Scanning...")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.brandSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandSecondary.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.brandSecondary.opacity(0.3), lineWidth: 1))
                }
            case .paused:
                HStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Paused")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.statusWarning)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.statusWarning.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.statusWarning.opacity(0.3), lineWidth: 1))
            case .inactive:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(nsColor: .systemGray))
                        .frame(width: 6, height: 6)
                    Text("Idle")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.textPrimary.opacity(0.06), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.textSecondary.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: — Card Grid (3 Columns)

    private let cardHeight: CGFloat = 112

    private var cardGrid: some View {
        HStack(alignment: .top, spacing: 14) {
            // Card 1 — Last Scan Score (tappable → detail sheet)
            DashboardCardView(
                id: .currentStatus,
                title: "Last Scan Score",
                icon: "scope",
                accentColor: Color.postureScoreColor(for: viewModel.todayScore),
                style: .progress,
                isSelected: false,
                primaryValue: viewModel.todayScore > 0 ? "\(viewModel.todayScore)" : "—",
                secondaryLabel: serviceLocator.postureService.lastRunStatus == .personNotDetected ? "Away from desk" : (viewModel.todayScore > 0 ? viewModel.todayScoreLabel : "No scans yet"),
                progress: viewModel.todayScore > 0 ? Double(viewModel.todayScore) / 100.0 : 0.0
            )
            .frame(height: cardHeight)

            // Card 2 — Today's Avg Score (tappable → detail sheet)
            DashboardCardView(
                id: .todayScore,
                title: "Today's Avg Score",
                icon: "chart.bar.fill",
                accentColor: Color.postureScoreColor(for: viewModel.averageScore),
                style: .progress,
                isSelected: false,
                primaryValue: viewModel.averageScore > 0 ? "\(viewModel.averageScore)" : "—",
                secondaryLabel: viewModel.todayScansCount > 0 ? "\(viewModel.todayScansCount) valid · \(viewModel.todayAwayCount) away" : (viewModel.todayAwayCount > 0 ? "0 valid · \(viewModel.todayAwayCount) away" : "No checks yet"),
                progress: viewModel.averageScore > 0 ? Double(viewModel.averageScore) / 100.0 : 0.0
            )
            .frame(height: cardHeight)
        }
    }

    // MARK: — Posture Advisor Panel (directly on dashboard)

    private var postureAdvisorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Section header ────────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.brandSecondary.opacity(0.12))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.brandSecondary)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Suggestions")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.textPrimary)
                    Text("Personalised ergonomic advice based on your posture scans today")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Line below header
            Divider().opacity(0.35)

            // ── Body ──────────────────────────────────────────────────────
            Group {
                if serviceLocator.postureService.lastRunStatus == .noScanYet {
                    noScanBanner
                } else {
                    // Shows two-column layout for both successful scans AND away state.
                    // The left column adapts to show "Not Detected" when away.
                    twoColumnScanDetail
                }
            }
            .padding(16)
        }
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 18))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    // MARK: Away banner
    private var awayBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.statusWarning)
            VStack(alignment: .leading, spacing: 3) {
                Text("Away from Desk")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.statusWarning)
                Text("Sit in frame to check your alignment. The camera will check again automatically.")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: No-scan banner
    private var noScanBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.brandSecondary)
            VStack(alignment: .leading, spacing: 3) {
                Text("Start Monitoring")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text("Click 'Start Monitoring' to receive posture evaluations and workstation advice.")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Two-column scan detail
    private var twoColumnScanDetail: some View {
        let isAway = serviceLocator.postureService.lastRunStatus == .personNotDetected

        return HStack(alignment: .top, spacing: 0) {

            // ── LEFT: Last Scan ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                Label("LAST SCAN", systemImage: "scope")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.textTertiary)
                    .tracking(0.6)

                if isAway {
                    // Away state — show not-detected badge + context
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.slash.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.statusWarning)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Not Detected")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.statusWarning)
                                Text("Away from desk")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.textSecondary)
                            }
                        }

                        // Show last valid scan score if we have one
                        if viewModel.todayScansCount > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last valid scan")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.textTertiary)
                                    .tracking(0.3)
                                let sc = viewModel.averageScore >= 80 ? Color.statusSuccess : Color.statusWarning
                                HStack(alignment: .firstTextBaseline, spacing: 5) {
                                    Text("~\(viewModel.averageScore)")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(sc)
                                    Text("avg today")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                } else {
                    // Normal scan state
                    // Score + label + trend vs average
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        let sc = viewModel.todayScore >= 80 ? Color.statusSuccess : Color.statusWarning
                        Text("\(viewModel.todayScore)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(sc)
                        Text(viewModel.todayScoreLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(sc)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(sc.opacity(0.1), in: Capsule())
                    }

                    // Trend vs today's average (only meaningful after ≥2 scans)
                    if viewModel.todayScansCount > 1 {
                        let trend = viewModel.scoreTrendVsAverage
                        let trendColor: Color = trend >= 0 ? .statusSuccess : .statusWarning
                        HStack(spacing: 4) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 9, weight: .bold))
                            Text("\(trend >= 0 ? "+" : "")\(trend) vs today's avg")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(trendColor)
                    }

                    // Checkpoint list — with specific failure reason shown
                    if !viewModel.lastCheckRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(viewModel.lastCheckRecommendations) { item in
                                let col = item.isGood ? Color.statusSuccess : Color.statusWarning
                                let ic  = item.isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 5) {
                                        Image(systemName: ic)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(col)
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(item.isGood ? "Good" : "Fix")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(col)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(col.opacity(0.08), in: Capsule())
                                    }
                                    if !item.isGood {
                                        Text(item.details)
                                            .font(.system(size: 9.5, weight: .medium))
                                            .foregroundStyle(.textSecondary)
                                            .lineLimit(2)
                                            .padding(.leading, 15)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 14)

            // ── Vertical divider ──────────────────────────────────────────
            Rectangle()
                .fill(Color.drGlassSpecularBorder)
                .frame(width: 1)
                .padding(.vertical, 2)

            // ── RIGHT: Coach Recommendation ───────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                Label("COACH RECOMMENDATION", systemImage: "lightbulb.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.textTertiary)
                    .tracking(0.6)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.brandSecondary, Color.textTertiary)

                // Workspace advice
                Text(viewModel.overallWorkspaceAdvice)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)

                // Quick action tip
                if viewModel.todayScansCount > 0 {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.brandSecondary)
                            .padding(.top, 1)
                        Text(viewModel.motivationalTip)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.brandPrimary.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.brandPrimary.opacity(0.12), lineWidth: 1))
                }

                // Per-category mini progress bars (today's trend)
                if !viewModel.categoryRates.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TODAY'S PATTERN")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(.textTertiary)
                            .tracking(0.5)
                        ForEach(viewModel.categoryRates) { cat in
                            let col: Color = cat.goodRate >= 0.8 ? .statusSuccess
                                           : cat.goodRate >= 0.5 ? .statusWarning
                                           : .statusError
                            HStack(spacing: 6) {
                                Text(cat.shortName)
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(.textSecondary)
                                    .frame(width: 54, alignment: .leading)
                                // Fixed-width progress bar
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.textTertiary.opacity(0.1))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(col)
                                        .frame(width: max(4, 68 * cat.goodRate), height: 4)
                                }
                                .frame(width: 68)
                                Text("\(Int(cat.goodRate * 100))%")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(col)
                                    .frame(width: 28, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 14)
        }
    }

    // MARK: — Action Bar (Hollow Glass Buttons: Cyan text, Purple outline)


    // MARK: — History Tab

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Posture History")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(viewModel.totalScansCount) checks evaluated")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                HistoryDashboardView(viewModel: viewModel)
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
