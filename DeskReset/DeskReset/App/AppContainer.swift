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
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                } catch {
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
    }
}
