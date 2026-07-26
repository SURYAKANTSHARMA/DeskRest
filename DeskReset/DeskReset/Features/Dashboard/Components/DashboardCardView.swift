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

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .overlay(selectionRing)
        .shadow(
            color: isSelected ? accentColor.opacity(0.18) : Color.black.opacity(0.04),
            radius: isSelected ? 10 : 4,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(duration: 0.25), value: isSelected)
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
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                }
                if let lbl = primaryLabel {
                    Text(lbl)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.textPrimary)
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.caption)
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
                        .stroke(accentColor.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress ?? 0)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    Text("\(Int((progress ?? 0) * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                }
                .frame(width: 44, height: 44)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 3) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                        .contentTransition(.numericText())
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.caption)
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
            HStack(alignment: .center, spacing: 10) {
                if let val = primaryValue {
                    Text(val)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                }
                if let badge = badge, let bc = badgeColor {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(bc.opacity(0.15), in: Capsule())
                        .foregroundStyle(bc)
                }
            }
            if let sub = secondaryLabel {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
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
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)
                }
                if let lbl = primaryLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.forward.circle")
                            .font(.caption2)
                            .foregroundStyle(.textTertiary)
                        Text(lbl)
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }
                if let sub = secondaryLabel {
                    Text(sub)
                        .font(.caption2)
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: — Shared Sub-views

    private var cardHeader: some View {
        HStack(spacing: 0) {
            // Icon pill
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.13))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Spacer()

            // Placeholder label if no real data yet
            if isPlaceholder {
                Text("Placeholder")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.textTertiary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .systemGray).opacity(0.12), in: Capsule())
            }
        }

        .overlay(alignment: .leading) {
            // Card title bottom-aligned
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.textSecondary)
                .offset(x: 44)           // right of icon
                .padding(.leading, 8)
        }
    }

    // MARK: — Backgrounds

    private var cardBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.08),
                        Color(nsColor: .controlBackgroundColor)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(Color(nsColor: .controlBackgroundColor))
    }

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(
                isSelected ? accentColor.opacity(0.5) : accentColor.opacity(0.08),
                lineWidth: isSelected ? 1.5 : 1
            )
    }
}
