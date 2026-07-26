//
//  BreakHistoryView.swift
//  DeskReset
//

import SwiftUI

struct BreakHistoryView: View {

    let sessions: [BreakSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Label("Recent Breaks", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }

            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .padding(16)
        .background(.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: — Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.largeTitle)
                    .foregroundStyle(.textTertiary)
                Text("No breaks recorded yet")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.vertical, 24)
            Spacer()
        }
    }

    // MARK: — Session List

    private var sessionList: some View {
        VStack(spacing: 0) {
            ForEach(sessions) { session in
                sessionRow(session)

                if session.id != sessions.last?.id {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
    }

    private func sessionRow(_ session: BreakSession) -> some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(breakColor(session.breakType).opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: session.breakType.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(breakColor(session.breakType))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.breakType.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textPrimary)
                Text(session.startDate.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            // Duration + status
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.displayDuration)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.textPrimary)
                Label(
                    session.wasCompleted ? "Completed" : "Skipped",
                    systemImage: session.wasCompleted ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.caption2)
                .foregroundStyle(session.wasCompleted ? .statusSuccess : .statusWarning)
                .labelStyle(.iconOnly)
            }
        }
        .padding(.vertical, 8)
    }

    private func breakColor(_ type: BreakType) -> Color {
        switch type {
        case .micro: return .breakMicro
        case .short: return .breakShort
        case .long:  return .breakLong
        }
    }
}

#Preview {
    BreakHistoryView(sessions: [])
        .frame(width: 400)
        .padding()
}
