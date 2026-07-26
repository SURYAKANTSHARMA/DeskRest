//
//  NotificationSettingsView.swift
//  DeskReset
//

import SwiftUI

struct NotificationSettingsView: View {

    @Binding var notificationsEnabled: Bool
    @Binding var soundEnabled: Bool
    var onRequestPermission: (() -> Void)?

    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
                Toggle("Play sound", isOn: $soundEnabled)
                    .disabled(!notificationsEnabled)
            }

            Section("Permission") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Permission")
                            .font(.subheadline)
                        Text("Allow DeskReset to send break reminders.")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Button("Request Access") {
                        onRequestPermission?()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Posture Alerts") {
                HStack {
                    Label("Posture Detection", systemImage: "camera.viewfinder")
                    Spacer()
                    Text("Coming Soon")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.statusInfo.opacity(0.12), in: Capsule())
                        .foregroundStyle(Color.statusInfo)
                }
                .foregroundStyle(Color.textSecondary)
            }
        }
        .formStyle(.grouped)
    }
}
