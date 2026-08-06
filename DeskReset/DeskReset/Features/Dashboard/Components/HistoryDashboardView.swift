//
//  HistoryDashboardView.swift
//  DeskReset
//

import SwiftUI
import SwiftData

struct HistoryDashboardView: View {

    let viewModel: DashboardViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header stats
            HStack(spacing: 14) {
                // Total Scans Card
                HistoryStatCard(
                    title: "Total Scans",
                    value: "\(viewModel.totalScansCount)",
                    subtitle: "checks evaluated",
                    icon: "scope",
                    accentColor: .brandPrimary
                )
                
                // Average Score Card
                HistoryStatCard(
                    title: "Average Score",
                    value: viewModel.averagePostureScore > 0 ? "\(viewModel.averagePostureScore)" : "—",
                    subtitle: scoreText(viewModel.averagePostureScore),
                    icon: "chart.bar.fill",
                    accentColor: Color.postureScoreColor(for: viewModel.averagePostureScore)
                )
            }

            // Daily Wise Report Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily History Report")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                    .padding(.top, 4)

                if viewModel.dailyReports.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(viewModel.dailyReports) { report in
                                DailyReportRow(report: report)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(.textTertiary)
                Text("No scan history recorded yet")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                Text("Start monitoring to build your history dashboard.")
                    .font(.caption2)
                    .foregroundStyle(.textTertiary)
            }
            .padding(.vertical, 40)
            Spacer()
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.0)],
                        startPoint: .top, endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    private func scoreText(_ score: Int) -> String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        case 1..<40:   return "Needs Work"
        default:       return "No scans yet"
        }
    }
}

// MARK: - History Stat Card

struct HistoryStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accentColor: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(accentColor)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.textPrimary)

                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.textPrimary)

                Text(subtitle)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ── Glassmorphism ────────────────────────────────────────────────
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.brandPrimary.opacity(0.08) : Color.white.opacity(0.04))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
                        startPoint: .top, endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isHovered ? Color.brandSecondary.opacity(0.5) : Color.drGlassSpecularBorder,
                    lineWidth: isHovered ? 1.5 : 1.0
                )
        )
        .shadow(
            color: isHovered ? Color.brandPrimary.opacity(0.18) : Color.black.opacity(0.08),
            radius: isHovered ? 10 : 5, y: isHovered ? 4 : 2
        )
        .scaleEffect(isHovered ? 1.012 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Daily Report Row

struct DailyReportRow: View {
    let report: DailyHistoryReport
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            // Date Column
            VStack(alignment: .leading, spacing: 2) {
                Text(report.date.formatted(.dateTime.weekday().month().day()))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(report.date.formatted(.dateTime.year()))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
            .frame(width: 80, alignment: .leading)

            Divider()
                .frame(height: 24)

            // Top Issue column
            HStack(spacing: 6) {
                if let issue = report.topIssue, let icon = report.topIssueIcon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.statusWarning)
                    Text(issue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                } else if report.averageScore > 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.statusSuccess)
                    Text("Perfect Alignment")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                } else {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.textTertiary)
                    Text("No scans evaluated")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                }
            }

            Spacer()

            // Scans Count Badge
            HStack(spacing: 3) {
                Image(systemName: "scope")
                    .font(.system(size: 9))
                Text("\(report.totalScans) scan\(report.totalScans == 1 ? "" : "s")")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.textPrimary.opacity(0.04), in: Capsule())

            // Score Badge
            ZStack {
                Circle()
                    .fill(Color.postureScoreColor(for: report.averageScore).opacity(0.12))
                    .frame(width: 32, height: 32)
                Text(report.averageScore > 0 ? "\(report.averageScore)" : "—")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.postureScoreColor(for: report.averageScore))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        // ── Glassmorphism ────────────────────────────────────────────────
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.brandPrimary.opacity(0.07) : Color.white.opacity(0.03))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.0)],
                        startPoint: .top, endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isHovered ? Color.brandSecondary.opacity(0.45) : Color.drGlassSpecularBorder,
                    lineWidth: isHovered ? 1.5 : 1.0
                )
        )
        .shadow(
            color: isHovered ? Color.brandPrimary.opacity(0.15) : Color.black.opacity(0.07),
            radius: isHovered ? 8 : 4, y: isHovered ? 3 : 2
        )
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
