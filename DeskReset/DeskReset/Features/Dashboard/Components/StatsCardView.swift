//
//  StatsCardView.swift
//  DeskReset
//

import SwiftUI

struct StatsCardView: View {

    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    var trend: Trend = .neutral

    enum Trend {
        case up, down, neutral
        var icon: String {
            switch self {
            case .up:      return "arrow.up.right"
            case .down:    return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        var color: Color {
            switch self {
            case .up:      return .statusSuccess
            case .down:    return .statusError
            case .neutral: return .textSecondary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon + Trend
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: trend.icon)
                        .font(.caption2.weight(.bold))
                    // Reserved space for a trend percentage label
                }
                .foregroundStyle(trend.color)
            }

            // Values
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.textPrimary.opacity(0.02))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StatsCardView(
            title: "Breaks Today",
            value: "5",
            subtitle: "Goal: 8",
            icon: "figure.walk",
            accentColor: .brandPrimary,
            trend: .up
        )
        StatsCardView(
            title: "Streak",
            value: "3",
            subtitle: "days in a row",
            icon: "flame.fill",
            accentColor: .orange,
            trend: .neutral
        )
    }
    .padding()
    .frame(width: 500)
}
