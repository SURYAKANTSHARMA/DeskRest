//
//  DashboardCardView.swift
//  DeskReset
//
//  Premium card component used for all 5 Dashboard placeholder cards.
//

import SwiftUI

// MARK: — Card Style

enum DashboardCardStyle {
    case standard   // icon + value + subtitle
    case progress   // icon + progress ring + subtitle
    case status     // large icon + status text
    case timeline   // icon + time + detail
}

// MARK: — Main Card View

struct DashboardCardView: View {

    let id: DashboardCardID
    let title: String
    let icon: String
    let accentColor: Color
    var style: DashboardCardStyle = .standard
    var isSelected: Bool          = false

    // Content slots
    var primaryValue: String?     = nil
    var primaryLabel: String?     = nil
    var secondaryLabel: String?   = nil
    var progress: Double?         = nil      // 0–1
    var badge: String?            = nil
    var badgeColor: Color?        = nil
    var isPlaceholder: Bool       = false

    var onTap: (() -> Void)?      = nil

    @State private var isHovered: Bool = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        // ── Glassmorphism background ─────────────────────────────────────
        // Layer order (back → front):
        //   1. ultraThinMaterial  — frosted blur
        //   2. tint fill          — subtle colour overlay at low opacity
        //   3. specular shimmer   — top-edge highlight for depth
        //   4. selection ring     — border
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isSelected
                        ? Color.brandPrimary.opacity(0.12)
                        : (isHovered ? Color.brandPrimary.opacity(0.07) : Color.white.opacity(0.04))
                )
        }
        .overlay {
            // Specular top-edge shimmer (glass highlight)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .allowsHitTesting(false)
        }
        .overlay(selectionRing)
        .shadow(
            color: isSelected
                ? Color.brandPrimary.opacity(0.35)
                : (isHovered ? Color.brandPrimary.opacity(0.18) : Color.black.opacity(0.10)),
            radius: isSelected ? 14 : (isHovered ? 10 : 6),
            y: isSelected ? 5 : 3
        )
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.012 : 1.0))
        .onHover { isHovered = $0 }
        .animation(.spring(duration: 0.25), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    // MARK: — Card Content

    @ViewBuilder
    private var cardContent: some View {
        switch style {
        case .standard:  standardLayout
        case .progress:  progressLayout
        case .status:    statusLayout
        case .timeline:  timelineLayout
        }
    }

    // MARK: — Standard Layout

    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 2) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                }
                if let lbl = primaryLabel {
                    Text(lbl)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Progress Layout

    private var progressLayout: some View {
        HStack(alignment: .top, spacing: 10) {
            // ── Left: header + big score ───────────────────────────────
            VStack(alignment: .leading, spacing: 0) {
                cardHeader
                Spacer(minLength: 10)
                VStack(alignment: .leading, spacing: 3) {
                    if let val = primaryValue {
                        Text(val)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.textPrimary)
                            .contentTransition(.numericText())
                    }
                    if let sub = secondaryLabel {
                        Text(sub)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 8)

            // ── Right: progress ring ───────────────────────────────
            ZStack {
                // Track ring
                Circle()
                    .stroke(accentColor.opacity(0.14), lineWidth: 5.5)
                // Fill arc — solid colour with glow
                Circle()
                    .trim(from: 0, to: CGFloat(progress ?? 0))
                    .stroke(accentColor,
                            style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.9), value: progress)
                    .shadow(color: accentColor.opacity(0.50), radius: 6)
                // Centre label
                VStack(spacing: 0) {
                    Text("\(Int((progress ?? 0) * 100))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                    Text("%")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(accentColor.opacity(0.65))
                }
            }
            .frame(width: 52, height: 52)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Status Layout

    private var statusLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader
            Spacer(minLength: 0)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .center, spacing: 6) {
                        if let val = primaryValue {
                            Text(val)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.textPrimary)
                        }
                        if let badge = badge, let bc = badgeColor {
                            Text(badge.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(bc.opacity(0.18), in: Capsule())
                                .foregroundStyle(bc)
                        }
                    }
                    if let sub = secondaryLabel {
                        Text(sub)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
                Spacer(minLength: 6)
                // Glowing posture pulse wave
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.brandAccent)
                    .shadow(color: Color.brandAccent.opacity(0.4), radius: 5)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Timeline Layout

    private var timelineLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardHeader
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 3) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                }
                if let lbl = primaryLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward.circle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(accentColor)
                        Text(lbl)
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(.textPrimary)
                    }
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Shared Sub-views

    private var cardHeader: some View {
        HStack(spacing: 8) {
            // Icon tile — accent-matched background with border
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(accentColor.opacity(0.22), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
    }

    // MARK: — Backgrounds

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(
                isSelected
                    ? AnyShapeStyle(Color.brandPrimary)
                    : (isHovered
                        ? AnyShapeStyle(Color.brandPrimary.opacity(0.6))
                        : AnyShapeStyle(Color.drGlassSpecularBorder)),
                lineWidth: isSelected ? 1.5 : 1.0
            )
    }
}
