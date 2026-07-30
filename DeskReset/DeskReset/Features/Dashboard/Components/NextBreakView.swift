//
//  NextBreakView.swift
//  DeskReset
//
//  Circular progress ring showing countdown to next break.
//

import SwiftUI

struct NextBreakView: View {

    let remainingText: String
    let progress: Double          // 0.0 → 1.0
    let breakType: BreakType
    var onTakeBreak: (() async -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.brandPrimary, .brandAccent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 4) {
                    Image(systemName: breakType.icon)
                        .font(.title2)
                        .foregroundStyle(.brandPrimary)
                    Text(remainingText)
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.textPrimary)
                    Text("until \(breakType.label.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
            .frame(width: 140, height: 140)

            // Action button
            if let onTakeBreak {
                Button {
                    Task { await onTakeBreak() }
                } label: {
                    Label("Take Break Now", systemImage: "play.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .controlSize(.regular)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.textPrimary.opacity(0.02))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.brandPrimary.opacity(0.25), Color.textSecondary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    NextBreakView(
        remainingText: "42:00",
        progress: 0.3,
        breakType: .short
    ) {}
    .frame(width: 250)
    .padding()
}
