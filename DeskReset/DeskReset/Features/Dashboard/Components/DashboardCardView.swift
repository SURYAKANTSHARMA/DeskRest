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
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isSelected
                        ? Color.brandPrimary.opacity(0.14)
                        : (isHovered ? Color.brandPrimary.opacity(0.06) : Color.drCardBackground)
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .overlay(selectionRing)
        .shadow(
            color: isSelected ? Color.brandPrimary.opacity(0.3) : (isHovered ? Color.brandPrimary.opacity(0.15) : Color.black.opacity(0.06)),
            radius: isSelected ? 12 : (isHovered ? 8 : 4),
            y: isSelected ? 4 : 2
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
        VStack(alignment: .leading, spacing: 14) {
            cardHeader
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 4) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                }
                if let lbl = primaryLabel {
                    Text(lbl)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Progress Layout

    private var progressLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                cardHeader
                Spacer()
                // Mini ring
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.18), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress ?? 0)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    Text("\(Int((progress ?? 0) * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 46, height: 46)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Status Layout

    private var statusLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader
            Spacer(minLength: 0)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        if let val = primaryValue {
                            Text(val)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.textPrimary)
                        }
                        if let badge = badge, let bc = badgeColor {
                            Text(badge.capitalized)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(bc.opacity(0.18), in: Capsule())
                                .foregroundStyle(bc)
                        }
                    }
                    if let sub = secondaryLabel {
                        Text(sub)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                // Glowing posture pulse wave (Option A Cyberpunk Glass feature)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.brandSecondary.opacity(0.5), radius: 6)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Timeline Layout

    private var timelineLayout: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 5) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                }
                if let lbl = primaryLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward.circle")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(accentColor)
                        Text(lbl)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.textPrimary)
                    }
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Shared Sub-views

    private var cardHeader: some View {
        HStack(spacing: 10) {
            // Icon squircle tile (Option A: drIconTileBackground)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.drIconTileBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text(title)
                .font(.system(size: 14.5, weight: .bold))
                .foregroundStyle(.textPrimary)

            Spacer()
        }
    }

    // MARK: — Backgrounds

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(
                isSelected
                    ? AnyShapeStyle(LinearGradient(colors: [Color.brandPrimary, Color.brandSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : (isHovered
                        ? AnyShapeStyle(LinearGradient(colors: [Color.brandPrimary.opacity(0.7), Color.brandSecondary.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.drGlassSpecularBorder)),
                lineWidth: isSelected ? 1.5 : 1.0
            )
    }
}
