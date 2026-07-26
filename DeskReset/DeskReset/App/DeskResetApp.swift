//
//  DeskResetApp.swift
//  DeskReset
//

import SwiftUI
import SwiftData

@main
struct DeskResetApp: App {

    @State private var appContainer = AppContainer()

    var body: some Scene {

        // MARK: — Dashboard Window (primary window scene)
        WindowGroup("Dashboard", id: AppWindowID.dashboard) {
            DashboardView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
        }
        .defaultSize(width: 860, height: 580)
        .windowResizability(.contentSize)

        // MARK: — Menu Bar (popover window style)
        MenuBarExtra("DeskReset", systemImage: "figure.walk") {
            MenuBarView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
        }
        .menuBarExtraStyle(.window)

        // MARK: — Camera Debug Window
        Window("Camera Debug", id: AppWindowID.cameraDebug) {
            CameraDebugView()
                .environment(appContainer.serviceLocator)
        }
        .defaultSize(width: 760, height: 510)
        .windowResizability(.contentSize)

        // MARK: — Settings (opens on Cmd+,)
        Settings {
            SettingsView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
        }
    }
}

// MARK: — Window identifiers
enum AppWindowID {
    static let dashboard   = "dashboard"
    static let cameraDebug = "camera-debug"
}
