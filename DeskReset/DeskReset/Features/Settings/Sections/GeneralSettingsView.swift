//
//  GeneralSettingsView.swift
//  DeskReset
//

import SwiftUI

struct GeneralSettingsView: View {

    @Binding var launchAtLogin: Bool
    @Binding var showInDock: Bool

    @State private var showPrivacyPolicy: Bool = false
    @State private var showTermsOfUse: Bool    = false

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
                LabeledContent("Developer") {
                    Text("Suryakant Sharma")
                        .foregroundStyle(Color.textSecondary)
                }
                LabeledContent("Copyright") {
                    Text("© 2025 DeskReset. All rights reserved.")
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Section("Support & Reviews") {
                Button {
                    AppRatingService.shared.rateOnAppStore(source: "general_settings")
                } label: {
                    HStack {
                        Label("Rate DeskReset on App Store", systemImage: "star.fill")
                            .foregroundStyle(Color.yellow)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    AppRatingService.shared.openFeedbackEmail(source: "general_settings")
                } label: {
                    HStack {
                        Label("Send Feedback & Support", systemImage: "envelope.fill")
                            .foregroundStyle(Color.brandSecondary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section("Legal") {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showTermsOfUse = true
                } label: {
                    HStack {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalView(document: .privacyPolicy)
        }
        .sheet(isPresented: $showTermsOfUse) {
            LegalView(document: .termsOfUse)
        }
    }
}
