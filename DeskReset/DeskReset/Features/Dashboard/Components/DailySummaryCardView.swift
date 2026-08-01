//
//  DailySummaryCardView.swift
//  DeskReset
//
//  Expanded Daily Summary card — shows posture score ring, break progress,
//  top detected posture issue, monitoring time, and a motivational tip.
//

import SwiftUI

struct DailySummaryCardView: View {

    // MARK: - Inputs
    let score: Int
    let scoreLabel: String
    let breaksDone: Int
    let breakGoal: Int
    let monitoringUptime: String
    let topIssue: String?
    let topIssueIcon: String?
    let motivationalTip: String
    let isMonitoring: Bool

    @State private var isHovered = false
    @State private var ringAppeared = false

    // MARK: - Derived
    private var scoreProgress: Double { Double(score) / 100.0 }
    private var breakProgress: Double { breakGoal > 0 ? min(Double(breaksDone) / Double(breakGoal), 1.0) : 0 }
    private var accentColor: Color { Color.postureScoreColor(for: score) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(isHovered ? Color.brandPrimary.opacity(0.06) : Color.drCardBackground)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isHovered ? Color.brandPrimary.opacity(0.6) : Color.drGlassSpecularBorder,
                    lineWidth: isHovered ? 1.5 : 1.0
                )

            VStack(alignment: .leading, spacing: 0) {
                headerRow

                HStack(alignment: .center, spacing: 14) {
                    scoreRing
                    statsColumn
                }
                .padding(.top, 10)

                Spacer(minLength: 6)
                breakProgressBar
                Spacer(minLength: 8)
                motivationalFooter
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .shadow(
            color: isHovered ? Color.brandPrimary.opacity(0.15) : Color.black.opacity(0.06),
            radius: isHovered ? 8 : 4, y: 2
        )
        .scaleEffect(isHovered ? 1.012 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) { ringAppeared = true }
        }
    }

    // MARK: — Header

    private var headerRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.drIconTileBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)
            }
            Text("Daily Summary")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundStyle(.textPrimary)
            Spacer()
            if isMonitoring {
                HStack(spacing: 4) {
                    Circle().fill(Color.statusSuccess).frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(Color.statusSuccess)
                }
                .padding(.horizontal, 8).padding(.vertical, 3.5)
                .background(Color.statusSuccess.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: — Score Ring

    private var scoreRing: some View {
        ZStack {
            Circle().stroke(accentColor.opacity(0.15), lineWidth: 7)
            Circle()
                .trim(from: 0, to: ringAppeared ? scoreProgress : 0)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.9), value: ringAppeared)
            VStack(spacing: 0) {
                Text(score == 0 ? "—" : "\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())
                if score > 0 {
                    Text(scoreLabel)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(accentColor)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        }
        .frame(width: 66, height: 66)
    }

    // MARK: — Stats Column

    private var statsColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(monitoringUptime == "—" ? "Not monitoring" : "\(monitoringUptime) active")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.textSecondary)
            } icon: {
                Image(systemName: "timer")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            }

            Label {
                Text("\(breaksDone)/\(breakGoal) breaks taken")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.textSecondary)
            } icon: {
                Image(systemName: "figure.walk")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.statusSuccess)
            }

            if let issue = topIssue, let icon = topIssueIcon {
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 9, weight: .bold))
                    Text(issue).font(.system(size: 9.5, weight: .bold)).lineLimit(1).truncationMode(.tail)
                }
                .foregroundStyle(Color.statusWarning)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color.statusWarning.opacity(0.12), in: Capsule())
            } else if score > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 9, weight: .bold))
                    Text("No issues").font(.system(size: 9.5, weight: .bold))
                }
                .foregroundStyle(Color.statusSuccess)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color.statusSuccess.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: — Break Progress Bar

    private var breakProgressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Break Goal")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                Spacer()
                Text("\(breaksDone) of \(breakGoal)")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.brandPrimary.opacity(0.12)).frame(height: 5)
                    Capsule()
                        .fill(breakProgress >= 1.0 ? Color.statusSuccess : Color.brandPrimary)
                        .frame(width: geo.size.width * (ringAppeared ? breakProgress : 0), height: 5)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: ringAppeared)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: — Motivational Footer

    private var motivationalFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.statusWarning)
            Text(motivationalTip)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.textSecondary)
                .lineLimit(1).truncationMode(.tail)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color.statusWarning.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}
