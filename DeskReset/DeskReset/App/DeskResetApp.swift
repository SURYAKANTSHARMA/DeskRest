//
//  DeskResetApp.swift
//  DeskReset
//

import SwiftUI
import SwiftData

// Firebase is conditionally imported — app compiles before SPM package is added.
// Once GoogleService-Info.plist + SPM packages are added, this activates.
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct DeskResetApp: App {

    @State private var appContainer = AppContainer()

    // Configure Firebase as early as possible (before any scene is created).
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        AnalyticsService.shared.setAnonymousUserID()
        AnalyticsService.shared.configureDebugView()
    }

    var body: some Scene {

        // MARK: — Dashboard Window (primary window scene)
        Window("Dashboard", id: AppWindowID.dashboard) {
            DashboardView()
                .environment(appContainer.serviceLocator)
                .modelContainer(appContainer.modelContainer)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1100, height: 640)
        .windowResizability(.automatic)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)

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
        .commands {
            CommandGroup(after: .help) {
                Divider()
                Button("Rate DeskReset on Mac App Store...") {
                    AppRatingService.shared.rateOnAppStore(source: "macos_help_menu")
                }
                Button("Send Feedback to Developer...") {
                    AppRatingService.shared.openFeedbackEmail(source: "macos_help_menu")
                }
            }
        }
    }
}

// MARK: — Window identifiers
enum AppWindowID {
    static let dashboard   = "dashboard"
    static let cameraDebug = "camera-debug"
}
