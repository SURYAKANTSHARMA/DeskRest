//
//  ServiceLocator.swift
//  DeskReset
//
//  Lightweight DI container injected into the SwiftUI environment.
//  Access in views with: @Environment(ServiceLocator.self)
//

import Foundation
import Observation

@Observable
final class ServiceLocator {

    // MARK: - Services (protocol-typed for testability)
    let timerService: any TimerServiceProtocol
    let breakService: any BreakServiceProtocol
    let notificationService: any NotificationServiceProtocol
    let postureService: any PostureServiceProtocol
    let cameraService: (any CameraServiceProtocol)?
    let ergonomicAdvisorService: any ErgonomicAdvisorServiceProtocol

    // MARK: - Init
    init(
        timerService: any TimerServiceProtocol,
        breakService: any BreakServiceProtocol,
        notificationService: any NotificationServiceProtocol,
        postureService: any PostureServiceProtocol,
        cameraService: (any CameraServiceProtocol)? = nil,
        ergonomicAdvisorService: (any ErgonomicAdvisorServiceProtocol)? = nil
    ) {
        self.timerService             = timerService
        self.breakService             = breakService
        self.notificationService      = notificationService
        self.postureService           = postureService
        self.cameraService            = cameraService
        self.ergonomicAdvisorService  = ergonomicAdvisorService ?? ErgonomicAdvisorService()
    }
}
