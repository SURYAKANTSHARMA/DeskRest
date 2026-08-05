//
//  GeneralSettingsView.swift
//  DeskReset
//

import SwiftUI

struct GeneralSettingsView: View {

    @Binding var launchAtLogin: Bool
    @Binding var showInDock: Bool

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showInDock)
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
