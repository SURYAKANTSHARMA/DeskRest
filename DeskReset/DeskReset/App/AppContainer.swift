//
//  AppContainer.swift
//  DeskReset
//
//  Composition root — owns the ModelContainer and all long-lived services.
//  Includes self-healing SwiftData store recovery if schema migration fails.
//

import Foundation
import SwiftData
import Observation
import OSLog

@Observable
final class AppContainer {

    // MARK: - Public Dependencies
    let modelContainer: ModelContainer
    let serviceLocator: ServiceLocator

    // MARK: - Init
    init() {
        // --- SwiftData setup ---
        let schema = Schema([
            BreakSession.self,
            UserPreferences.self,
            PostureLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            Logger.data.error("DeskReset: ModelContainer error (\(error)). Self-healing store reset...")
            AnalyticsService.shared.recordError(error, context: ["operation": "model_container_disk_init"])
            AnalyticsService.shared.log(.dataStoreError(operation: "model_container_disk_init", error: error.localizedDescription))

            // Self-healing: remove stale/incompatible disk store files if migration fails
            let storeURL = config.url
            let walURL   = storeURL.appendingPathExtension("wal")
            let shmURL   = storeURL.appendingPathExtension("shm")

            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)

            do {
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                Logger.data.error("DeskReset: Disk container creation failed again (\(error)). Falling back to in-memory store.")
                AnalyticsService.shared.recordError(error, context: ["operation": "model_container_disk_retry_fallback_memory"])
                AnalyticsService.shared.log(.dataStoreError(operation: "model_container_disk_retry", error: error.localizedDescription))
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                } catch {
                    AnalyticsService.shared.recordError(error, context: ["operation": "model_container_fallback_fatal"])
                    fatalError("DeskReset: Failed to create fallback ModelContainer — \(error)")
                }
            }
        }

        // --- Services ---
        let timerService            = TimerService()
        let breakService            = BreakService()
        breakService.modelContext   = ModelContext(modelContainer)
        let notificationService     = NotificationService()
        let cameraService           = CameraService()
        let postureService          = PostureService(cameraService: cameraService)
        postureService.modelContext = ModelContext(modelContainer)
        let ergonomicAdvisorService = ErgonomicAdvisorService()

        serviceLocator = ServiceLocator(
            timerService: timerService,
            breakService: breakService,
            notificationService: notificationService,
            postureService: postureService,
            cameraService: cameraService,
            ergonomicAdvisorService: ergonomicAdvisorService
        )

        // Note: Onboarding completion is persisted via "dr_onboarding_complete" in UserDefaults.
        // Do NOT reset it here — users should only see onboarding once.

        // MARK: — Analytics session context
        // Set Crashlytics custom keys so every crash report includes useful context.
        let analytics = AnalyticsService.shared
        analytics.setCrashlyticsKey("monitoring_active", value: "false")
        analytics.setCrashlyticsKey("app_version",
                                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")
    }
}
