//
//  GeneralSettingsView.swift
//  DeskReset
//

import SwiftUI

struct GeneralSettingsView: View {

    @Binding var launchAtLogin: Bool
    @Binding var showInDock: Bool
    @Binding var dailyBreakGoal: Int
    @Binding var defaultBreakType: BreakType

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showInDock)
            }

            Section("Defaults") {
                Picker("Default break type", selection: $defaultBreakType) {
                    ForEach(BreakType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Stepper("Daily goal: \(dailyBreakGoal) breaks", value: $dailyBreakGoal, in: 1...24)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(AppSettings.default.appVersion)
                        .foregroundStyle(Color.textSecondary)
                }
                LabeledContent("Build") {
                    Text(AppSettings.default.buildNumber)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
