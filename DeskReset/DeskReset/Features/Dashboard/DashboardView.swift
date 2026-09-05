//
//  DashboardView.swift
//  DeskReset
//
//  Redesigned home page matching Figma design:
//  Dark navy theme · Hero score ring · Body Analysis · AI Coach · Score Timeline
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @State private var viewModel = DashboardViewModel()
    @State private var selectedSidebar: SidebarItem = .overview
    @State private var showCalibrationSheet: Bool = false
    @State private var showRecoveryRoutineSheet: Bool = false
    @State private var showRatingPrompt: Bool = false
    @State private var selectedCoachTab: CoachTab = .deskFix
    @State private var monitoringDotPulse: Bool = false
    @State private var scoreRingAnimate: Bool = false

    // MARK: — Coach Tabs

    enum CoachTab: String, CaseIterable, Identifiable {
        case deskFix   = "Desk Fix"
        case microReset = "30s Reset"
        case habitTip  = "Habit Tip"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .deskFix:    return "display"
            case .microReset: return "figure.cooldown"
            case .habitTip:   return "lightbulb.fill"
            }
        }
    }

    // MARK: — Sidebar Items

    enum SidebarItem: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case history  = "History"
        case settings = "Settings"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2.fill"
            case .history:  return "clock.arrow.circlepath"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: — Dark Theme Colors

    static let navyBg       = Color(red: 0.051, green: 0.059, blue: 0.102)
    static let cardBg       = Color(red: 0.086, green: 0.094, blue: 0.153)
    static let cardBorder   = Color.white.opacity(0.08)
    static let purpleAccent = Color(red: 0.486, green: 0.231, blue: 0.929)
    static let cyanAccent   = Color(red: 0.024, green: 0.714, blue: 0.831)
    static let textPrimW    = Color.white
    static let textSecW     = Color.white.opacity(0.55)
    static let textTertW    = Color.white.opacity(0.35)

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
                        .frame(minWidth: 540, maxWidth: .infinity, minHeight: 440)
                }
                .navigationSplitViewStyle(.prominentDetail)
                .frame(minWidth: 820, idealWidth: 1100, maxWidth: 1400, minHeight: 600)
                .navigationTitle("")
                .preferredColorScheme(.dark)
                .background(WindowAppearanceModifier())
                .background(DashboardView.navyBg.ignoresSafeArea())
                .onAppear {
                    viewModel.configure(with: serviceLocator)
                    viewModel.loadStats(modelContext: modelContext)
                    withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                        scoreRingAnimate = true
                    }
                    AnalyticsService.shared.log(.screenViewed(screenName: selectedSidebar.rawValue.lowercased()))
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowSettingsTab"))) { _ in
                    withAnimation(.spring(duration: 0.25)) {
                        selectedSidebar = .settings
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowRatingPrompt"))) { _ in
                    showRatingPrompt = true
                }
                .sheet(isPresented: $showRatingPrompt) {
                    AppRatingPromptView()
                }
                .onReceive(NotificationCenter.default.publisher(for: .postureScanDidComplete)) { _ in
                    viewModel.loadStats(modelContext: modelContext)
                    viewModel.refreshMonitoringState()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedSidebar) { _, newTab in
            AnalyticsService.shared.log(.screenViewed(screenName: newTab.rawValue.lowercased()))
        }
        .onChange(of: serviceLocator.postureService.nextCheckTime) { _, _ in
            viewModel.loadStats(modelContext: modelContext)
            viewModel.refreshMonitoringState()
        }
        .onChange(of: serviceLocator.postureService.postureScore) { _, _ in
            viewModel.loadStats(modelContext: modelContext)
        }
        .onChange(of: serviceLocator.postureService.lastRunStatus) { _, _ in
            viewModel.loadStats(modelContext: modelContext)
        }
        .onChange(of: serviceLocator.postureService.isMonitoring) { _, _ in
            viewModel.refreshMonitoringState()
        }
        .animation(.spring(duration: 0.5), value: viewModel.showOnboarding)
    }

    // MARK: — Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            Divider().overlay(DashboardView.cardBorder)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    DarkSidebarButton(item: item, isSelected: selectedSidebar == item) {
                        withAnimation(.spring(duration: 0.25)) { selectedSidebar = item }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)

            Spacer(minLength: 0)

            if viewModel.todayScansCount > 0 {
                streakBadge
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }

            Divider().overlay(DashboardView.cardBorder)
            sidebarMonitoringControl
        }
        .background(DashboardView.cardBg)
        .overlay(
            Rectangle().fill(DashboardView.cardBorder).frame(width: 1),
            alignment: .trailing
        )
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        .toolbar(removing: .sidebarToggle)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable().scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: DashboardView.purpleAccent.opacity(0.4), radius: 4, y: 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).fill(DashboardView.purpleAccent).frame(width: 28, height: 28)
                        Image(systemName: "figure.stand").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("DeskReset").font(.headline).foregroundStyle(DashboardView.textPrimW).lineLimit(1)
                Text("Wellness Hub").font(.caption2).foregroundStyle(DashboardView.textSecW).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var streakBadge: some View {
        HStack(spacing: 8) {
            Text("🔥").font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(max(1, viewModel.todayScansCount / 10))-day streak")
                    .font(.system(size: 11, weight: .bold)).foregroundStyle(DashboardView.textPrimW)
                Text("Score ≥ 80 every day")
                    .font(.system(size: 9.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DashboardView.purpleAccent.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DashboardView.purpleAccent.opacity(0.3), lineWidth: 1))
        )
    }

    private var sidebarMonitoringControl: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.monitoringState == .active ? DashboardView.cyanAccent : DashboardView.textSecW)
                    .frame(width: 7, height: 7)
                    .shadow(color: viewModel.monitoringState == .active ? DashboardView.cyanAccent.opacity(monitoringDotPulse ? 0.9 : 0.2) : .clear, radius: monitoringDotPulse ? 6 : 2)
                    .onAppear {
                        guard viewModel.monitoringState == .active else { return }
                        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { monitoringDotPulse = true }
                    }
                Text(viewModel.monitoringState == .active ? "Active · \(viewModel.monitoringUptime)" : "Inactive")
                    .font(.system(size: 11.5, weight: .semibold).monospacedDigit())
                    .foregroundStyle(DashboardView.textSecW).lineLimit(1)
                Spacer()
            }

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if viewModel.monitoringState == .active {
                        viewModel.stopMonitoring()
                    } else {
                        if viewModel.isCalibrated { viewModel.startMonitoring() }
                        else { showCalibrationSheet = true }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.monitoringState == .active ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(viewModel.monitoringState == .active ? "Stop Monitoring" : "Start Monitoring")
                        .font(.system(size: 12, weight: .bold)).lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.monitoringState == .active
                              ? Color(red: 0.85, green: 0.22, blue: 0.22)
                              : DashboardView.purpleAccent)
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.monitoringState)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .sheet(isPresented: $showCalibrationSheet) {
            CalibrationView()
                .environment(serviceLocator)
                .onDisappear { viewModel.loadStats(modelContext: modelContext) }
        }
    }

    // MARK: — Detail Pane

    @ViewBuilder
    private var detailPane: some View {
        switch selectedSidebar {
        case .overview: overviewContent
        case .history:  historyContent
        case .settings: settingsContent
        }
    }

    // MARK: — Overview

    private var overviewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                overviewHeader
                if !viewModel.isCalibrated { calibrationBanner }
                mainGrid
                scoreTimelineSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(dashboardBackground)
    }

    // MARK: — Overview Header

    private var overviewHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greetingText)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(DashboardView.textPrimW)
                HStack(spacing: 8) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.system(size: 12.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                    if viewModel.todayScansCount > 0 {
                        Text("·").foregroundStyle(DashboardView.textTertW)
                        Text("\(viewModel.todayScansCount) scans today")
                            .font(.system(size: 12.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                    }
                }
            }
            Spacer()
            HStack(spacing: 10) {
                liveStatusBadge
                Button {
                    viewModel.loadStats(modelContext: modelContext)
                    viewModel.refreshMonitoringState()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DashboardView.textSecW)
                        .padding(7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DashboardView.cardBg)
                                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(DashboardView.cardBorder, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain).help("Refresh dashboard")
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    // MARK: — Main Grid

    private var mainGrid: some View {
        HStack(alignment: .top, spacing: 18) {
            heroScorePanel
                .frame(minWidth: 320, maxWidth: 430)
            VStack(spacing: 16) {
                bodyAnalysisPanel
                aiCoachPanel
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: — Hero Score Panel

    private var heroScorePanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DashboardView.cardBorder, lineWidth: 1))

            HStack(alignment: .center, spacing: 20) {
                largeScoreRing.padding(.leading, 18)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("YOUR POSTURE SCORE · TODAY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .tracking(0.8)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(viewModel.todayScore > 0 ? "\(viewModel.todayScore)" : "—")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(DashboardView.textPrimW)
                                .contentTransition(.numericText())
                            if viewModel.todayScore > 0 {
                                Text("/ 100").font(.system(size: 17, weight: .medium)).foregroundStyle(Color.white.opacity(0.7))
                            }
                        }

                        if viewModel.todayScore > 0 {
                            HStack(spacing: 8) {
                                Text(viewModel.todayScoreLabel)
                                    .font(.system(size: 11.5, weight: .bold)).foregroundStyle(scoreColor)
                                    .padding(.horizontal, 9).padding(.vertical, 3.5)
                                    .background(scoreColor.opacity(0.18), in: Capsule())

                                if viewModel.todayScansCount > 1 {
                                    let trend = viewModel.scoreTrendVsAverage
                                    let trendColor = trend >= 0 ? Color(red: 0.063, green: 0.725, blue: 0.506) : Color(red: 0.961, green: 0.620, blue: 0.043)
                                    HStack(spacing: 3) {
                                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 9.5, weight: .bold))
                                        Text("\(trend >= 0 ? "+" : "")\(trend) from yesterday")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundStyle(trendColor)
                                }
                            }
                        }
                    }

                    HStack(spacing: 20) {
                        miniStat(value: "\(viewModel.todayScansCount)", label: "Valid scans")
                        miniStat(value: "\(viewModel.todayAwayCount)", label: "Away count")
                        miniStat(
                            value: viewModel.nextCheckIn == "—" ? "—" : viewModel.nextCheckIn.replacingOccurrences(of: "in ", with: ""),
                            label: "Next scan"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 18)
            }
            .padding(.vertical, 24)
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardView.textPrimW)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
        }
    }

    // MARK: — Score Ring

    private var largeScoreRing: some View {
        ZStack {
            Circle().fill(scoreColor.opacity(0.06)).frame(width: 160, height: 160)
            Circle().stroke(DashboardView.cardBorder, lineWidth: 11).frame(width: 134, height: 134)
            Circle()
                .trim(from: 0, to: CGFloat(scoreRingAnimate ? (viewModel.todayScore > 0 ? Double(viewModel.todayScore) / 100.0 : 0) : 0))
                .stroke(
                    AngularGradient(colors: [scoreColor.opacity(0.6), scoreColor, scoreColor.opacity(0.8)],
                                   center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .frame(width: 134, height: 134)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.2, dampingFraction: 0.75), value: viewModel.todayScore)
                .shadow(color: scoreColor.opacity(0.5), radius: 8)

            VStack(spacing: 2) {
                Text(viewModel.todayScore > 0 ? "\(viewModel.todayScore)" : "—")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(DashboardView.textPrimW)
                    .contentTransition(.numericText())
                if viewModel.todayScore > 0 {
                    Text(viewModel.todayScoreLabel).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(scoreColor)
                } else if viewModel.monitoringState == .active {
                    Text("Scanning...").font(.system(size: 11.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                } else {
                    Text("Idle").font(.system(size: 11.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                }
            }
        }
        .frame(width: 160, height: 160)
    }

    private var scoreColor: Color { Color.postureScoreColor(for: viewModel.todayScore) }

    // MARK: — Body Analysis Panel

    private var bodyAnalysisPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DashboardView.cardBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("BODY ANALYSIS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .tracking(1.0)
                    Spacer()
                }

                HStack(alignment: .center, spacing: 18) {
                    Image("BodyAnalysisFigure")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(categoryBars, id: \.name) { cat in
                            bodyBar(name: cat.name, rate: cat.rate, color: cat.color)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(18)
        }
    }

    private struct CategoryBar { let name: String; let rate: Double; let color: Color }

    private var categoryBars: [CategoryBar] {
        let colors: [Color] = [
            DashboardView.cyanAccent,
            Color(red: 0.961, green: 0.620, blue: 0.043),
            Color(red: 0.063, green: 0.725, blue: 0.506),
            DashboardView.cyanAccent
        ]
        if viewModel.categoryRates.isEmpty {
            let names = ["Head", "Shoulders", "Back", "Torso"]
            return names.enumerated().map { i, n in CategoryBar(name: n, rate: 0, color: colors[i]) }
        }
        return viewModel.categoryRates.enumerated().map { i, cat in
            CategoryBar(name: cat.shortName, rate: cat.goodRate, color: colors[min(i, colors.count - 1)])
        }
    }

    private func bodyBar(name: String, rate: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))
                .frame(width: 72, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 6.5)
                    Capsule().fill(color).frame(width: geo.size.width * max(0, min(1, rate)), height: 6.5)
                        .animation(.easeOut(duration: 0.8), value: rate)
                }
            }
            .frame(height: 6.5)
            Text("\(Int(rate * 100))%")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 38, alignment: .trailing)
        }
    }

    // MARK: — AI Coach Panel

    private var aiCoachPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DashboardView.cardBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 14) {
                // Header row
                HStack(spacing: 9) {
                    ZStack {
                        Circle().fill(DashboardView.purpleAccent.opacity(0.25)).frame(width: 30, height: 30)
                        Image(systemName: "sparkles").font(.system(size: 13, weight: .bold)).foregroundStyle(DashboardView.purpleAccent)
                    }
                    Text("AI Coach").font(.system(size: 16, weight: .bold)).foregroundStyle(DashboardView.textPrimW)
                    Text("AI")
                        .font(.system(size: 9.5, weight: .bold)).foregroundStyle(DashboardView.cyanAccent)
                        .padding(.horizontal, 6).padding(.vertical, 2.5)
                        .background(DashboardView.cyanAccent.opacity(0.18), in: Capsule())
                        .overlay(Capsule().strokeBorder(DashboardView.cyanAccent.opacity(0.35), lineWidth: 1))

                    Spacer()

                    if let guidance = viewModel.aiCoachGuidance {
                        HStack(spacing: 4) {
                            Image(systemName: guidance.badgeIcon).font(.system(size: 10, weight: .bold))
                            Text(guidance.badgeText).font(.system(size: 10.5, weight: .bold))
                        }
                        .foregroundStyle(badgeColor(for: guidance.type))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(badgeColor(for: guidance.type).opacity(0.14), in: Capsule())
                        .overlay(Capsule().strokeBorder(badgeColor(for: guidance.type).opacity(0.3), lineWidth: 1))
                    }
                }

                if let guidance = viewModel.aiCoachGuidance {
                    // Diagnostic Headline & Data Metric
                    VStack(alignment: .leading, spacing: 5) {
                        Text(guidance.headline)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(DashboardView.textPrimW)

                        HStack(spacing: 5) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 11, weight: .semibold))
                            Text(guidance.dataMetricText)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(DashboardView.cyanAccent)

                        Text(guidance.diagnosticExplanation)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Guidance Switcher Tabs
                    HStack(spacing: 6) {
                        ForEach(CoachTab.allCases) { tab in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { selectedCoachTab = tab }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: tab.icon).font(.system(size: 11, weight: .semibold))
                                    Text(tab.rawValue).font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(selectedCoachTab == tab ? DashboardView.textPrimW : Color.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedCoachTab == tab ? DashboardView.purpleAccent.opacity(0.4) : Color.white.opacity(0.06))
                                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selectedCoachTab == tab ? DashboardView.purpleAccent.opacity(0.7) : Color.clear, lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Selected Tab Content Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))

                        Group {
                            switch selectedCoachTab {
                            case .deskFix:
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text(guidance.ergonomicFixTitle)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(DashboardView.textPrimW)
                                        Spacer()
                                        Text(guidance.targetArea)
                                            .font(.system(size: 9.5, weight: .semibold))
                                            .foregroundStyle(DashboardView.cyanAccent)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(DashboardView.cyanAccent.opacity(0.14), in: Capsule())
                                    }
                                    Text(guidance.ergonomicFixDetails)
                                        .font(.system(size: 12.5, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            case .microReset:
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text(guidance.microExerciseTitle)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(DashboardView.textPrimW)
                                        Spacer()
                                        Text(guidance.microExerciseDuration)
                                            .font(.system(size: 9.5, weight: .semibold))
                                            .foregroundStyle(DashboardView.purpleAccent)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(DashboardView.purpleAccent.opacity(0.18), in: Capsule())
                                    }
                                    Text(guidance.microExerciseInstruction)
                                        .font(.system(size: 12.5, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            case .habitTip:
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color(red: 0.961, green: 0.620, blue: 0.043))
                                        Text("Workday Ergonomic Habit")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(DashboardView.textPrimW)
                                    }
                                    Text(guidance.habitTip)
                                        .font(.system(size: 12.5, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Action Button
                    Button {
                        if !viewModel.isCalibrated {
                            showCalibrationSheet = true
                        } else {
                            showRecoveryRoutineSheet = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isCalibrated ? "figure.cooldown" : "figure.stand")
                                .font(.system(size: 13, weight: .bold))
                            Text(viewModel.isCalibrated ? "Start Guided Reset (2m)" : "Calibrate Baseline")
                                .font(.system(size: 13.5, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [DashboardView.purpleAccent, DashboardView.purpleAccent.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shadow(color: DashboardView.purpleAccent.opacity(0.35), radius: 5, y: 2)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(viewModel.overallWorkspaceAdvice)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
            .padding(18)
        }
        .sheet(isPresented: $showRecoveryRoutineSheet) {
            if let routine = viewModel.aiCoachGuidance?.routine {
                RecoveryRoutineView(routine: routine) {
                    AppRatingService.shared.recordRoutineCompleted()
                    if AppRatingService.shared.shouldPromptForRating() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            AppRatingService.shared.recordPromptShown(trigger: "recovery_routine_completion")
                            showRatingPrompt = true
                        }
                    }
                }
            }
        }
    }

    private func badgeColor(for type: AICoachGuidance.InsightType) -> Color {
        switch type {
        case .correction:     return Color(red: 0.961, green: 0.620, blue: 0.043)
        case .fatiguePattern: return Color(red: 0.961, green: 0.400, blue: 0.200)
        case .improving:      return Color(red: 0.063, green: 0.725, blue: 0.506)
        case .optimal:        return Color(red: 0.063, green: 0.725, blue: 0.506)
        case .setupGuide:     return DashboardView.cyanAccent
        }
    }

    // MARK: — Score Timeline

    private var scoreTimelineSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DashboardView.cardBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text("Score Timeline")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DashboardView.textPrimW)

                    if let range = timelineRange {
                        Text(range).font(.system(size: 11, weight: .medium)).foregroundStyle(DashboardView.textSecW).padding(.leading, 4)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Capsule().fill(DashboardView.purpleAccent).frame(width: 16, height: 2)
                        Text("Posture score").font(.system(size: 10.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                    }
                }

                if chartData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 28)).foregroundStyle(DashboardView.textTertW)
                        Text("Start monitoring to see your score timeline").font(.system(size: 12, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                    }
                    .frame(maxWidth: .infinity).frame(height: 120)
                } else {
                    scoreChart.frame(height: 140)
                }
            }
            .padding(20)
        }
    }

    private var timelineRange: String? {
        guard !chartData.isEmpty, let first = chartData.first, let last = chartData.last else { return nil }
        let fmt = DateFormatter(); fmt.dateFormat = "h:mma"
        return "Today · \(fmt.string(from: first.time).lowercased()) – \(fmt.string(from: last.time).lowercased())"
    }

    private var chartData: [ScoreTimelinePoint] {
        if !viewModel.todayTimelinePoints.isEmpty {
            if viewModel.todayTimelinePoints.count == 1, let single = viewModel.todayTimelinePoints.first {
                let earlier = ScoreTimelinePoint(time: single.time.addingTimeInterval(-60), score: single.score)
                return [earlier, single]
            }
            return viewModel.todayTimelinePoints
        }
        return []
    }

    @ViewBuilder
    private var scoreChart: some View {
        let data = chartData
        if data.isEmpty {
            Color.clear
        } else {
            Chart(data) { point in
                AreaMark(x: .value("Time", point.time), y: .value("Score", point.score))
                    .foregroundStyle(LinearGradient(
                        colors: [DashboardView.purpleAccent.opacity(0.3), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Time", point.time), y: .value("Score", point.score))
                    .foregroundStyle(DashboardView.purpleAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle().fill(DashboardView.purpleAccent).frame(width: 4, height: 4)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) { _ in
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        .foregroundStyle(DashboardView.textTertW)
                    AxisGridLine().foregroundStyle(DashboardView.cardBorder)
                }
            }
            .chartYAxis {
                AxisMarks(values: [60, 70, 80, 90, 100]) { _ in
                    AxisValueLabel().foregroundStyle(DashboardView.textTertW)
                    AxisGridLine().foregroundStyle(DashboardView.cardBorder)
                }
            }
            .chartYScale(domain: 50...100)
            .chartPlotStyle { plot in plot.background(Color.clear) }
        }
    }

    // MARK: — Live Status Badge

    private var liveStatusBadge: some View {
        Group {
            switch viewModel.monitoringState {
            case .active:
                let isAway = serviceLocator.postureService.lastRunStatus == .personNotDetected
                if isAway {
                    statusPill(icon: "person.fill.questionmark", text: "Away from Desk",
                               fg: Color(red: 0.961, green: 0.620, blue: 0.043),
                               bg: Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.15))
                } else {
                    statusPill(icon: "circle.fill", text: "Active",
                               fg: DashboardView.cyanAccent, bg: DashboardView.cyanAccent.opacity(0.15))
                }
            case .paused:
                statusPill(icon: "pause.circle.fill", text: "Paused",
                           fg: Color(red: 0.961, green: 0.620, blue: 0.043),
                           bg: Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.15))
            case .inactive:
                statusPill(icon: "circle.fill", text: "Idle",
                           fg: DashboardView.textSecW, bg: DashboardView.cardBorder)
            }
        }
    }

    private func statusPill(icon: String, text: String, fg: Color, bg: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 7, weight: .bold)).foregroundStyle(fg)
            Text(text).font(.system(size: 11, weight: .bold)).foregroundStyle(fg)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(bg, in: Capsule())
        .overlay(Capsule().strokeBorder(fg.opacity(0.3), lineWidth: 1))
    }

    // MARK: — Calibration Banner

    private var calibrationBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(DashboardView.cyanAccent.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "figure.stand").font(.title3).foregroundStyle(DashboardView.cyanAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Posture Baseline Required").font(.headline).foregroundStyle(DashboardView.textPrimW)
                Text("Take 10 seconds to calibrate your posture baseline for accurate monitoring.")
                    .font(.caption).foregroundStyle(DashboardView.textSecW)
            }
            Spacer()
            Button { showCalibrationSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").foregroundStyle(.white)
                    Text("Calibrate Now").foregroundStyle(.white)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(DashboardView.purpleAccent))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DashboardView.cyanAccent.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: — History Tab

    private var historyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Page header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Posture History")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(DashboardView.textPrimW)
                    HStack(spacing: 6) {
                        Text("\(viewModel.totalScansCount) checks evaluated")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(DashboardView.textSecW)
                        if viewModel.dailyReports.count > 0 {
                            Text("·").foregroundStyle(DashboardView.textTertW)
                            Text("last \(viewModel.dailyReports.count) days")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(DashboardView.textSecW)
                        }
                    }
                }

                HistoryDashboardView(viewModel: viewModel)
            }
            .padding(24)
        }
        .background(dashboardBackground)
        .onAppear { viewModel.loadStats(modelContext: modelContext) }
    }

    // MARK: — Settings Tab

    @State private var selectedInterval: TimeInterval = 90
    @State private var showPrivacyPolicy: Bool = false
    @State private var showTermsOfUse: Bool    = false

    private let intervalOptions: [(label: String, value: TimeInterval)] = [
        ("90 seconds", 90), ("5 minutes", 300), ("10 minutes", 600), ("15 minutes", 900), ("30 minutes", 1800)
    ]

    private var settingsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Page header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings").font(.system(size: 24, weight: .bold)).foregroundStyle(DashboardView.textPrimW)
                    Text("Configure monitoring frequency, preferences, and legal info").font(.system(size: 12.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
                }

                // ── Monitoring Frequency ──────────────────────────────────
                settingsSectionCard(icon: "stopwatch.fill", title: "Monitoring Frequency") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose how frequently Vision AI scans your posture. Shorter intervals catch slouching quicker; longer intervals preserve system resources.")
                            .font(.system(size: 11.5, weight: .medium)).foregroundStyle(DashboardView.textSecW).lineSpacing(3)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SCAN INTERVAL").font(.system(size: 9.5, weight: .bold)).foregroundStyle(DashboardView.textTertW).tracking(0.5)
                            Picker("", selection: $selectedInterval) {
                                ForEach(intervalOptions, id: \.value) { Text($0.label).tag($0.value) }
                            }
                            .pickerStyle(.menu).labelsHidden().frame(width: 180)
                            .onChange(of: selectedInterval) { _, v in saveIntervalPreference(v) }
                        }
                    }
                }

                // ── About ─────────────────────────────────────────────────
                settingsSectionCard(icon: "info.circle.fill", title: "About DeskReset") {
                    VStack(spacing: 0) {
                        settingsRow(label: "Version",   value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        Divider().overlay(DashboardView.cardBorder).padding(.leading, 0)
                        settingsRow(label: "Build",     value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        Divider().overlay(DashboardView.cardBorder)
                        settingsRow(label: "Developer", value: "Suryakant Sharma")
                        Divider().overlay(DashboardView.cardBorder)
                        settingsRow(label: "Copyright", value: "© 2025 DeskReset")
                    }
                }

                // ── App Store & Community ─────────────────────────────────
                settingsSectionCard(icon: "star.fill", title: "App Store & Community") {
                    VStack(spacing: 0) {
                        legalLinkRow(
                            icon: "star.fill",
                            label: "Rate DeskReset on Mac App Store",
                            color: Color(red: 0.99, green: 0.76, blue: 0.18)
                        ) {
                            AppRatingService.shared.rateOnAppStore(source: "dashboard_settings")
                        }
                        Divider().overlay(DashboardView.cardBorder)
                        legalLinkRow(
                            icon: "envelope.fill",
                            label: "Contact Developer & Send Feedback",
                            color: DashboardView.cyanAccent
                        ) {
                            AppRatingService.shared.openFeedbackEmail(source: "dashboard_settings")
                        }
                    }
                }

                // ── Legal ─────────────────────────────────────────────────
                settingsSectionCard(icon: "lock.shield.fill", title: "Legal") {
                    VStack(spacing: 0) {
                        legalLinkRow(icon: "lock.shield.fill", label: "Privacy Policy",
                                     color: DashboardView.cyanAccent) { showPrivacyPolicy = true }
                        Divider().overlay(DashboardView.cardBorder)
                        legalLinkRow(icon: "doc.text.fill", label: "Terms of Use",
                                     color: DashboardView.purpleAccent) { showTermsOfUse = true }
                    }
                }
            }
            .padding(24)
        }
        .background(dashboardBackground)
        .onAppear { loadIntervalPreference() }
        .sheet(isPresented: $showPrivacyPolicy) { LegalView(document: .privacyPolicy) }
        .sheet(isPresented: $showTermsOfUse)    { LegalView(document: .termsOfUse) }
    }

    // MARK: — Settings helpers

    private func settingsSectionCard<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(DashboardView.purpleAccent.opacity(0.15)).frame(width: 28, height: 28)
                    Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(DashboardView.purpleAccent)
                }
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(DashboardView.textPrimW)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DashboardView.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DashboardView.cardBorder, lineWidth: 1))
        )
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12.5, weight: .medium)).foregroundStyle(DashboardView.textSecW)
            Spacer()
            Text(value).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(DashboardView.textPrimW)
        }
        .padding(.vertical, 10)
    }

    private func legalLinkRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(color).frame(width: 18)
                Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(DashboardView.textPrimW)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(DashboardView.textTertW)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadIntervalPreference() {
        if let prefs = try? modelContext.fetch(FetchDescriptor<UserPreferences>()).first {
            selectedInterval = prefs.monitoringInterval
        }
    }

    private func saveIntervalPreference(_ interval: TimeInterval) {
        do {
            let list = try modelContext.fetch(FetchDescriptor<UserPreferences>())
            let prefs = list.first ?? UserPreferences()
            if list.isEmpty { modelContext.insert(prefs) }
            prefs.monitoringInterval = interval
            try modelContext.save()
            serviceLocator.postureService.monitoringInterval = interval
            AnalyticsService.shared.log(.scanIntervalChanged(intervalSeconds: Int(interval)))
        } catch {}
    }

    // MARK: — Background

    private var dashboardBackground: some View {
        ZStack {
            DashboardView.navyBg.ignoresSafeArea()
            Circle().fill(DashboardView.purpleAccent.opacity(0.07)).frame(width: 400, height: 400).blur(radius: 60).offset(x: -100, y: -80).allowsHitTesting(false)
            Circle().fill(DashboardView.cyanAccent.opacity(0.04)).frame(width: 300, height: 300).blur(radius: 50).offset(x: 160, y: 100).allowsHitTesting(false)
        }
    }
}

// MARK: — Dark Sidebar Button

struct DarkSidebarButton: View {
    let item: DashboardView.SidebarItem
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? DashboardView.purpleAccent : (isHovered ? DashboardView.textPrimW : DashboardView.textSecW))
                    .frame(width: 18)
                Text(item.rawValue)
                    .font(.system(size: 13.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? DashboardView.textPrimW : (isHovered ? DashboardView.textPrimW : DashboardView.textSecW))
                    .fixedSize()
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.vertical, 9).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule().fill(DashboardView.purpleAccent).shadow(color: DashboardView.purpleAccent.opacity(0.4), radius: 8, x: 0, y: 2)
            } else if isHovered {
                Capsule().fill(DashboardView.purpleAccent.opacity(0.12))
            }
        }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: — Window Appearance Modifier

struct WindowAppearanceModifier: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.appearance = NSAppearance(named: .darkAqua)
                window.backgroundColor = NSColor(red: 0.051, green: 0.059, blue: 0.102, alpha: 1.0)
                window.titlebarAppearsTransparent = true
                window.isOpaque = true
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.appearance = NSAppearance(named: .darkAqua)
                window.backgroundColor = NSColor(red: 0.051, green: 0.059, blue: 0.102, alpha: 1.0)
                window.titlebarAppearsTransparent = true
            }
        }
    }
}

// MARK: — Preview

#Preview {
    DashboardView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService()
        ))
}
