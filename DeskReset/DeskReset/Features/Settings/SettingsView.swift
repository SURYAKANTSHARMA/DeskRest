//
//  SettingsView.swift
//  DeskReset
//
//  Native macOS Settings window — opens on Cmd+,
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $viewModel.launchAtLogin,
                showInDock: $viewModel.showInDock
            )
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            NotificationSettingsView(
                notificationsEnabled: $viewModel.notificationsEnabled,
                soundEnabled: $viewModel.soundEnabled
            ) {
                Task { await viewModel.requestNotificationPermission() }
            }
            .tabItem {
                Label("Notifications", systemImage: "bell.badge")
            }
        }
        .frame(minWidth: 480)
        .onAppear {
            viewModel.configure(with: serviceLocator)
            viewModel.loadPreferences(modelContext: modelContext)
        }
        .onChange(of: viewModel.notificationsEnabled) { _, _ in save() }
        .onChange(of: viewModel.soundEnabled)         { _, _ in save() }
        .onChange(of: viewModel.launchAtLogin)        { _, _ in save() }
        .onChange(of: viewModel.showInDock)           { _, _ in save() }
    }

    private func save() {
        viewModel.savePreferences(modelContext: modelContext)
    }
}

#Preview {
    SettingsView()
        .environment(ServiceLocator(
            timerService: TimerService(),
            breakService: BreakService(),
            notificationService: NotificationService(),
            postureService: PostureService()
        ))
}
