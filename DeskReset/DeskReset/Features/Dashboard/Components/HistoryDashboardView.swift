//
//  HistoryDashboardView.swift
//  DeskReset
//
//  Redesigned History tab matching Figma dark design:
//  3 stat cards · 7-Day bar trend · Daily Report list
//

import SwiftUI
import SwiftData
import Charts

struct HistoryDashboardView: View {

    let viewModel: DashboardViewModel

    // MARK: — Computed helpers

    private var bestDayReport: DailyHistoryReport? {
        viewModel.dailyReports.max(by: { $0.averageScore < $1.averageScore })
    }

    private var last7Days: [DailyHistoryReport] {
        Array(viewModel.dailyReports.prefix(7).reversed())
    }

    private var scoreLabel: String {
        switch viewModel.averagePostureScore {
        case 85...100: return "Excellent overall"
        case 65..<85:  return "Good overall"
        case 40..<65:  return "Fair overall"
        case 1..<40:   return "Needs work"
        default:       return "No data yet"
        }
    }

    // Color per score — matches Figma: green 80+, purple 70-79, red <70
    private func barColor(for score: Int) -> Color {
        switch score {
        case 80...100: return Color(red: 0.11, green: 0.42, blue: 0.35)   // dark teal-green
        case 70..<80:  return DashboardView.purpleAccent                   // purple
        default:       return Color(red: 0.55, green: 0.16, blue: 0.16)   // dark red
        }
    }

    // MARK: — Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            statCardsRow
            sevenDayTrend
            dailyReportSection
        }
    }

    // MARK: — Stat Cards

    private var statCardsRow: some View {
        HStack(spacing: 14) {
            // Total Scans
            DarkHistoryStatCard(
                label: "TOTAL SCANS",
                value: "\(viewModel.totalScansCount)",
                subtitle: "checks evaluated",
                subtitleColor: DashboardView.purpleAccent
            )

            // Average Score
            DarkHistoryStatCard(
                label: "AVERAGE SCORE",
                value: viewModel.averagePostureScore > 0 ? "\(viewModel.averagePostureScore)" : "—",
                subtitle: scoreLabel,
                subtitleColor: DashboardView.purpleAccent
            )

            // Best Day
            DarkHistoryStatCard(
                label: "BEST DAY",
                value: bestDayReport != nil ? "\(bestDayReport!.averageScore)" : "—",
                subtitle: bestDayReport != nil
                    ? bestDayReport!.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    : "No data",
                subtitleColor: Color(red: 0.063, green: 0.725, blue: 0.506) // teal-green
            )
        }
    }

    // MARK: — 7-Day Trend

    private var sevenDayTrend: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(DashboardView.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(DashboardView.cardBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                Text("7-Day Trend")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DashboardView.textPrimW)

                if last7Days.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(DashboardView.textTertW)
                            Text("No data for the last 7 days")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DashboardView.textSecW)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    trendBars
                }
            }
            .padding(18)
        }
    }

    private var trendBars: some View {
        let today = Calendar.current.startOfDay(for: Date())
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(last7Days) { report in
                let isToday = Calendar.current.isDate(report.date, inSameDayAs: today)
                let color = barColor(for: report.averageScore)
                let barH = max(20, CGFloat(report.averageScore) * 1.1)

                VStack(spacing: 5) {
                    // Score label above bar
                    Text("\(report.averageScore)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DashboardView.textSecW)

                    // Bar
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(height: barH)
                        .frame(maxWidth: .infinity)
                        .shadow(color: color.opacity(0.4), radius: 4, y: 2)

                    // Day label below bar
                    Text(report.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 10, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? DashboardView.textPrimW : DashboardView.textSecW)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 130)
    }

    // MARK: — Daily Report Section

    private var dailyReportSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(DashboardView.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(DashboardView.cardBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 0) {
                // Section header
                HStack {
                    Text("Daily Report")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DashboardView.textPrimW)
                    Spacer()
                    Text("\(viewModel.dailyReports.count) days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DashboardView.textSecW)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if viewModel.dailyReports.isEmpty {
                    emptyState
                        .padding(18)
                } else {
                    // Rows with dividers
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.dailyReports.enumerated()), id: \.element.id) { idx, report in
                            DarkDailyReportRow(report: report)

                            if idx < viewModel.dailyReports.count - 1 {
                                Divider()
                                    .overlay(DashboardView.cardBorder)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle).foregroundStyle(DashboardView.textTertW)
                Text("No scan history recorded yet")
                    .font(.subheadline).foregroundStyle(DashboardView.textSecW)
                Text("Start monitoring to build your history dashboard.")
                    .font(.caption2).foregroundStyle(DashboardView.textTertW)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }
}

// MARK: — Dark Stat Card

struct DarkHistoryStatCard: View {
    let label: String
    let value: String
    let subtitle: String
    let subtitleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(DashboardView.textTertW)
                .tracking(0.7)

            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardView.textPrimW)
                .contentTransition(.numericText())

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(subtitleColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DashboardView.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(DashboardView.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: — Dark Daily Report Row

struct DarkDailyReportRow: View {
    let report: DailyHistoryReport
    @State private var isHovered = false

    private var scoreColor: Color { Color.postureScoreColor(for: report.averageScore) }
    private var issueDotColor: Color {
        report.topIssue != nil
            ? Color(red: 0.961, green: 0.620, blue: 0.043)   // amber for issues
            : Color(red: 0.063, green: 0.725, blue: 0.506)   // green for clean
    }

    var body: some View {
        HStack(spacing: 14) {
            // Date column
            VStack(alignment: .leading, spacing: 2) {
                Text(report.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DashboardView.textPrimW)
                Text(report.date.formatted(.dateTime.year()))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DashboardView.textTertW)
            }
            .frame(width: 90, alignment: .leading)

            // Issue dot + label
            HStack(spacing: 7) {
                Circle()
                    .fill(issueDotColor)
                    .frame(width: 7, height: 7)
                if let issue = report.topIssue {
                    Text(issue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DashboardView.textSecW)
                        .lineLimit(1)
                } else {
                    Text("Perfect Alignment")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DashboardView.textSecW)
                }
            }

            Spacer()

            // Scan count
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 9, weight: .medium))
                Text("\(report.totalScans) scans")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .foregroundStyle(DashboardView.textTertW)

            // Score badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(scoreColor)
                    .frame(width: 40, height: 30)
                Text(report.averageScore > 0 ? "\(report.averageScore)" : "—")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(isHovered ? DashboardView.purpleAccent.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}
