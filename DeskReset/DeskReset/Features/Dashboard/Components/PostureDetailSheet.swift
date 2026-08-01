//
//  PostureDetailSheet.swift
//  DeskReset
//
//  Rich detail sheet that opens when the user taps the "Current Posture" card.
//  Shows live posture state, score breakdown, correction tips, and an AI insight
//  panel — all in the purple/cyan glassmorphic design language.
//

import SwiftUI

struct PostureDetailSheet: View {

    let monitoringState: MonitoringState
    let currentStatus: String
    let currentDetail: String
    let todayScore: Int
    let totalChecks: Int
    let topIssue: String?
    let topIssueIcon: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: — Animation states
    @State private var ringScale: CGFloat     = 0.6
    @State private var ringOpacity: Double    = 0
    @State private var pulseRing1: CGFloat    = 1.0
    @State private var pulseRing2: CGFloat    = 1.0
    @State private var contentSlide: CGFloat  = 24
    @State private var contentOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    private var accentColor: Color {
        switch monitoringState {
        case .active:   return .brandSecondary
        case .paused:   return .statusWarning
        case .inactive: return .brandPrimary
        }
    }

    private var scoreColor: Color { Color.postureScoreColor(for: todayScore) }

    private var statusIcon: String {
        switch monitoringState {
        case .active:   return "eye.fill"
        case .paused:   return "pause.circle.fill"
        case .inactive: return "circle.dotted"
        }
    }

    private var correctionTips: [(icon: String, tip: String)] {
        if let issue = topIssue {
            switch issue.lowercased() {
            case let s where s.contains("head"):
                return [
                    ("arrow.up", "Lift your chin slightly — bring ears above shoulders"),
                    ("display", "Raise your monitor to eye level"),
                    ("figure.stand", "Imagine a string pulling the crown of your head upward")
                ]
            case let s where s.contains("shoulder"):
                return [
                    ("arrow.backward.and.arrow.forward", "Roll shoulders back and down gently"),
                    ("figure.arms.open", "Open your chest — don't hunch forward"),
                    ("hand.raised", "Relax arms — elbows close to body at ~90°")
                ]
            case let s where s.contains("back") || s.contains("torso"):
                return [
                    ("figure.seated.side", "Engage core lightly — maintain natural S-curve"),
                    ("chair.lounge", "Adjust chair lumbar support to the curve of your back"),
                    ("timer", "Take a 2-minute stand break every 30 minutes")
                ]
            default:
                return [
                    ("figure.stand", "Sit tall — neutral spine, relaxed shoulders"),
                    ("timer", "Take a short break — you've been sitting too long"),
                    ("figure.walk", "Do the recovery routine to reset stiffness")
                ]
            }
        }
        if monitoringState == .active && todayScore >= 80 {
            return [
                ("checkmark.seal.fill", "Excellent alignment detected — keep it up!"),
                ("timer", "Remember to stand briefly every 45–60 minutes"),
                ("drop.fill", "Stay hydrated — it helps muscle endurance")
            ]
        }
        return [
            ("camera.viewfinder", "Start monitoring to receive real-time posture feedback"),
            ("figure.stand", "Calibrate your posture baseline for accurate scoring"),
            ("figure.walk", "Use recovery routines to build better posture habits")
        ]
    }

    var body: some View {
        ZStack {
            // ── Cosmic background ──
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            Circle()
                .fill(accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10))
                .frame(width: 500, height: 500)
                .blur(radius: 110)
                .offset(x: -80, y: -80)
            Circle()
                .fill(Color.brandPrimary.opacity(colorScheme == .dark ? 0.12 : 0.07))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 180, y: 160)

            VStack(spacing: 0) {
                headerRow
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                    .padding(.bottom, 16)

                Divider().opacity(0.4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero status orb
                        statusOrb
                            .padding(.top, 24)

                        // Score + checks row
                        statsRow
                            .offset(y: contentSlide)
                            .opacity(contentOpacity)

                        // Issue / status block
                        issueBlock
                            .offset(y: contentSlide)
                            .opacity(contentOpacity)

                        // AI correction tips
                        correctionTipsBlock
                            .offset(y: contentSlide)
                            .opacity(contentOpacity)

                        // AI insight footer
                        aiInsightBanner
                            .offset(y: contentSlide)
                            .opacity(contentOpacity)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
        .frame(width: 480, height: 580)
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                ringScale   = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                contentSlide   = 0
                contentOpacity = 1.0
            }
            // Continuous pulse rings (only when active)
            if monitoringState == .active {
                startPulseAnimation()
            }
            // Shimmer
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).delay(0.5)) {
                shimmerOffset = 400
            }
        }
    }

    // MARK: — Header

    private var headerRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Posture")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text("Live AI monitoring status")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: — Status Orb

    private var statusOrb: some View {
        return VStack(spacing: 16) {
            ZStack {
                // Pulse rings (behind orb)
                if monitoringState == .active {
                    Circle()
                        .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
                        .scaleEffect(pulseRing1)
                        .opacity(2.0 - pulseRing1)
                        .frame(width: 90, height: 90)

                    Circle()
                        .stroke(accentColor.opacity(0.10), lineWidth: 1)
                        .scaleEffect(pulseRing2)
                        .opacity(2.0 - pulseRing2)
                        .frame(width: 90, height: 90)
                }

                // Orb background
                Circle()
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 90, height: 90)
                    .overlay {
                        // Shimmer sweep
                        LinearGradient(
                            colors: [.clear, accentColor.opacity(0.2), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset - 200)
                        .clipShape(Circle())
                    }
                    .shadow(color: accentColor.opacity(0.35), radius: 18)

                // Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(accentColor)
                    .shadow(color: accentColor.opacity(0.5), radius: 8)
            }
            .scaleEffect(ringScale)
            .opacity(ringOpacity)

            // Status text below orb
            VStack(spacing: 6) {
                Text(currentStatus)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.textPrimary)

                Text(currentDetail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.textSecondary)

                // Live pill
                if monitoringState == .active {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.statusSuccess)
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.statusSuccess.opacity(0.6), radius: 4)
                        Text("AI VISION ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.statusSuccess)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.statusSuccess.opacity(0.10), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.statusSuccess.opacity(0.25), lineWidth: 1))
                }
            }
        }
    }

    // MARK: — Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(
                icon: "chart.bar.fill",
                label: "Today's Score",
                value: todayScore == 0 ? "—" : "\(todayScore)",
                color: scoreColor
            )
            miniStat(
                icon: "eye.fill",
                label: "Total Checks",
                value: totalChecks == 0 ? "0" : "\(totalChecks)",
                color: .brandPrimary
            )
            miniStat(
                icon: "waveform.path.ecg",
                label: "AI Status",
                value: monitoringState == .active ? "ON" : "OFF",
                color: monitoringState == .active ? .statusSuccess : .textTertiary
            )
        }
    }

    private func miniStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.statusWarning.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Color.statusWarning)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DETECTED ISSUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.textTertiary)
                            .tracking(0.5)
                        Text(issue)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Follow the correction tips below to improve your posture.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.statusWarning.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.statusWarning.opacity(0.22), lineWidth: 1.5))
            } else if monitoringState == .active {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.statusSuccess.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(Color.statusSuccess)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("POSTURE STATUS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.textTertiary)
                            .tracking(0.5)
                        Text("Great Posture Detected")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("AI Vision sees no posture issues right now.")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.statusSuccess.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.statusSuccess.opacity(0.22), lineWidth: 1.5))
            } else {
                EmptyView()
            }
        }
    }

    // MARK: — Correction Tips

    private var correctionTipsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandPrimary)
                Text("AI CORRECTION TIPS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.textTertiary)
                    .tracking(0.5)
            }

            ForEach(Array(correctionTips.enumerated()), id: \.offset) { i, tip in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: tip.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    Text(tip.tip)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 11))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
            }
        }
    }

    // MARK: — AI Insight Banner

    private var aiInsightBanner: some View {
        HStack(spacing: 12) {
            LinearGradient(
                colors: [Color.brandPrimary, Color.brandSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 4)
            .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.brandPrimary)
                    Text("DeskReset AI")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.brandPrimary)
                }
                Text(aiInsight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.brandPrimary.opacity(0.05), in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.brandPrimary.opacity(0.18), lineWidth: 1))
    }

    private var aiInsight: String {
        switch monitoringState {
        case .active:
            if let _ = topIssue {
                return "I've detected a posture deviation. Use the recovery routine or follow the tips above to correct your alignment and protect long-term spine health."
            }
            return "Your posture looks great right now! Maintaining this alignment reduces neck and back strain significantly. Keep it up."
        case .inactive:
            return "Start monitoring to activate Vision AI. I'll scan your posture every minute and alert you if I detect any issues."
        case .paused:
            return "Monitoring is paused. Resume it from the sidebar to continue receiving real-time posture guidance."
        }
    }

    // MARK: — Pulse Animation

    private func startPulseAnimation() {
        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
            pulseRing1 = 2.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulseRing2 = 2.2
            }
        }
    }
}
