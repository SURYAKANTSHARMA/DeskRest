//
//  DailySummaryDetailView.swift
//  DeskReset
//
//  Detailed daily wellness summary sheet — shown when the user taps
//  the "Daily Summary" card on the Dashboard.
//

import SwiftUI
import SwiftData

struct DailySummaryDetailView: View {

    // Data passed in from the card
    let score: Int
    let averageScore: Int
    let scoreLabel: String
    let totalScans: Int
    let monitoringUptime: String
    let topIssue: String?
    let topIssueIcon: String?
    let motivationalTip: String
    let isMonitoring: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var ringAppeared = false

    private var scoreProgress: Double { Double(score) / 100.0 }
    private var accentColor: Color { Color.postureScoreColor(for: score) }
    private var today: String {
        Date.now.formatted(date: .complete, time: .omitted)
    }

    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            Circle()
                .fill(accentColor.opacity(colorScheme == .dark ? 0.14 : 0.08))
                .frame(width: 500, height: 500)
                .blur(radius: 100)
                .offset(x: -100, y: -80)
            Circle()
                .fill(Color.brandSecondary.opacity(0.07))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 200, y: 140)

            VStack(spacing: 0) {
                // ── Header ──
                headerRow
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                    .padding(.bottom, 18)

                Divider()
                    .opacity(0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // ── Score hero block ──
                        scoreHeroBlock
                            .padding(.top, 20)

                        // ── Stats grid ──
                        statsGrid

                        // ── Top Issue / Status ──
                        issueBlock

                        // ── Motivational tip ──
                        tipBlock

                        // ── Monitoring status ──
                        monitoringBlock

                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
        .frame(width: 500, height: 540)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).delay(0.2)) {
                ringAppeared = true
            }
        }
    }

    // MARK: — Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily Posture Summary")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(today)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            if isMonitoring {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.statusSuccess)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.statusSuccess.opacity(0.7), radius: 4)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.statusSuccess)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.statusSuccess.opacity(0.10), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.statusSuccess.opacity(0.25), lineWidth: 1))
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: — Score Hero Block

    private var scoreHeroBlock: some View {
        HStack(spacing: 24) {
            // Ring
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: ringAppeared ? scoreProgress : 0)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.9), value: ringAppeared)

                VStack(spacing: 2) {
                    Text(score == 0 ? "—" : "\(score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                    Text(score == 0 ? "No data" : scoreLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }
            .frame(width: 110, height: 110)

            // Description
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Posture Score")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.textPrimary)
                    Text(scoreDescription)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Score tier pills
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.system(size: 10, weight: .bold))
                        Text("Latest: \(score)")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.10), in: Capsule())
                    .overlay(Capsule().strokeBorder(accentColor.opacity(0.25), lineWidth: 1))

                    if averageScore > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10, weight: .bold))
                            Text("Daily Avg: \(averageScore)")
                                .font(.system(size: 10.5, weight: .bold))
                        }
                        .foregroundStyle(Color.brandSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.brandSecondary.opacity(0.10), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.brandSecondary.opacity(0.25), lineWidth: 1))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 16))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accentColor.opacity(0.22), lineWidth: 1.5))
        .shadow(color: accentColor.opacity(0.10), radius: 10, y: 4)
    }

    // MARK: — Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "timer",
                label: "Active Time",
                value: monitoringUptime == "—" ? "Not started" : monitoringUptime,
                color: .brandPrimary
            )
            statCard(
                icon: "scope",
                label: "Checks Checked",
                value: "\(totalScans)",
                color: .statusSuccess
            )
            statCard(
                icon: "chart.bar.fill",
                label: "Daily Average",
                value: averageScore > 0 ? "\(averageScore)" : "—",
                color: Color.postureScoreColor(for: averageScore)
            )
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                Text(label)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 13))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }


    // MARK: — Issue Block

    private var issueBlock: some View {
        Group {
            if let issue = topIssue, let icon = topIssueIcon {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.statusWarning.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.statusWarning)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Top Posture Issue")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.textTertiary)
                            .textCase(.uppercase)
                        Text(issue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Focus on correcting this for a better score.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.statusWarning.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.statusWarning.opacity(0.22), lineWidth: 1))
            } else if score > 0 {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.statusSuccess.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.statusSuccess)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Posture Status")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.textTertiary)
                            .textCase(.uppercase)
                        Text("No issues detected")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Excellent work — keep maintaining this posture!")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.statusSuccess.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.statusSuccess.opacity(0.22), lineWidth: 1))
            } else {
                EmptyView()
            }
        }
    }

    // MARK: — Motivational Tip

    private var tipBlock: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.statusWarning)
            VStack(alignment: .leading, spacing: 3) {
                Text("Today's Tip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.textTertiary)
                    .textCase(.uppercase)
                Text(motivationalTip)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.statusWarning.opacity(0.07), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.statusWarning.opacity(0.20), lineWidth: 1))
    }

    // MARK: — Monitoring Block

    private var monitoringBlock: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isMonitoring ? Color.brandSecondary.opacity(0.12) : Color.textTertiary.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: isMonitoring ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isMonitoring ? Color.brandSecondary : Color.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Monitoring Status")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.textTertiary)
                    .textCase(.uppercase)
                Text(isMonitoring ? "Active · \(monitoringUptime)" : "Not currently monitoring")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
            }

            Spacer()

            Circle()
                .fill(isMonitoring ? Color.statusSuccess : Color.textTertiary)
                .frame(width: 10, height: 10)
                .shadow(color: isMonitoring ? Color.statusSuccess.opacity(0.6) : .clear, radius: 5)
        }
        .padding(14)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 13))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    // MARK: — Helpers

    private var scoreDescription: String {
        switch score {
        case 85...100: return "Outstanding! Your posture has been excellent throughout the day."
        case 65..<85:  return "Good posture overall. A few adjustments can push you to excellent."
        case 40..<65:  return "Fair posture today. Focus on sitting upright and taking breaks."
        case 1..<40:   return "Posture needs attention. Try the recovery routines to reset."
        default:       return "Start monitoring to receive your posture score and insights."
        }
    }

    private var scoreTierIcon: String {
        switch score {
        case 85...100: return "star.fill"
        case 65..<85:  return "checkmark.circle.fill"
        case 40..<65:  return "exclamationmark.triangle.fill"
        case 1..<40:   return "xmark.circle.fill"
        default:       return "minus.circle.fill"
        }
    }
}
