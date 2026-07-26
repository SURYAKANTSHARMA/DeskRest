//
//  BreakSettingsView.swift
//  DeskReset
//

import SwiftUI

struct BreakSettingsView: View {

    @Binding var breakInterval: Double
    @Binding var shortBreakDuration: Double
    @Binding var longBreakDuration: Double
    @Binding var microBreakDuration: Double

    var body: some View {
        Form {
            Section("Schedule") {
                durationRow(
                    label: "Break every",
                    value: $breakInterval,
                    range: 900...7200,
                    step: 300,
                    displayFormatter: intervalLabel
                )
            }

            Section("Break Durations") {
                durationRow(
                    label: "Micro break",
                    value: $microBreakDuration,
                    range: 30...300,
                    step: 30,
                    displayFormatter: durationLabel
                )
                durationRow(
                    label: "Short break",
                    value: $shortBreakDuration,
                    range: 60...1800,
                    step: 60,
                    displayFormatter: durationLabel
                )
                durationRow(
                    label: "Long break",
                    value: $longBreakDuration,
                    range: 300...3600,
                    step: 300,
                    displayFormatter: durationLabel
                )
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Row builder

    private func durationRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        displayFormatter: (Double) -> String
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            Stepper(
                displayFormatter(value.wrappedValue),
                value: value,
                in: range,
                step: step
            )
            .fixedSize()
        }
    }

    // MARK: - Formatters

    private func intervalLabel(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        return mins >= 60 ? "\(mins / 60)h \(mins % 60 > 0 ? "\(mins % 60)m" : "")" : "\(mins)m"
    }

    private func durationLabel(_ seconds: Double) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        let m = s / 60; let rem = s % 60
        return rem > 0 ? "\(m)m \(rem)s" : "\(m)m"
    }
}
