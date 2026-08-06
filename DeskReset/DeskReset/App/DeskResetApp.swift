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
        Window("Dashboard", id: AppWindowID.dashboard) {
            DashboardView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
        }
        .defaultSize(width: 860, height: 580)
        .windowResizability(.contentSize)

        // MARK: — Menu Bar (popover window style)
        MenuBarExtra {
            MenuBarView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
        } label: {
            if let image = NSImage(named: "MenuBarIcon") {
                let _ = { image.size = NSSize(width: 32, height: 24) }()
                Image(nsImage: image)
            } else {
                Image(systemName: "figure.seated.side")
            }
        }
        .menuBarExtraStyle(.window)

        // MARK: — Camera Debug Window
        Window("Camera Debug", id: AppWindowID.cameraDebug) {
            CameraDebugView()
                .environment(appContainer.serviceLocator)
        }
        .defaultSize(width: 760, height: 510)
        .windowResizability(.contentSize)
    }
}

// MARK: — Window identifiers
enum AppWindowID {
    static let dashboard   = "dashboard"
    static let cameraDebug = "camera-debug"
}
