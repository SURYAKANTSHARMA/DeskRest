//
//  BreakService.swift
//  DeskReset
//
//  Placeholder implementation — break session logic not yet implemented.
//

import Foundation
import Observation
import OSLog

@Observable
final class BreakService: BreakServiceProtocol {

    // MARK: - State
    var isOnBreak: Bool         = false
    var currentSession: BreakSession? = nil

    // MARK: - Actions

    func startBreak(type: BreakType) async {
        // TODO: Implement break start (create session, notify timer, show UI overlay)
        Logger.services.info("BreakService.startBreak(type: \(type.rawValue))")
        isOnBreak      = true
        currentSession = BreakSession(startDate: .now, breakType: type)
    }

    func endBreak() async {
        // TODO: Implement break end (persist session, update stats)
        Logger.services.info("BreakService.endBreak()")
        isOnBreak      = false
        currentSession = nil
    }

    func skipBreak() async {
        // TODO: Implement skip logic (reschedule timer)
        Logger.services.info("BreakService.skipBreak()")
        isOnBreak = false
    }
}
