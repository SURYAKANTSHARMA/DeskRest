//
//  BreakService.swift
//  DeskReset
//
//  Placeholder implementation — break session logic not yet implemented.
//

import Foundation
import Observation
import OSLog
import SwiftData

@Observable
final class BreakService: BreakServiceProtocol {

    // MARK: - State
    var modelContext: ModelContext?
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
        Logger.services.info("BreakService.endBreak()")
        if let session = currentSession {
            session.endDate = .now
            session.duration = session.endDate!.timeIntervalSince(session.startDate)
            session.wasCompleted = true
            modelContext?.insert(session)
            try? modelContext?.save()
            AnalyticsService.shared.log(.breakTaken(durationMinutes: max(1, Int(session.duration / 60))))
            AppRatingService.shared.recordSessionCompleted()
        }
        isOnBreak      = false
        currentSession = nil
    }

    func skipBreak() async {
        Logger.services.info("BreakService.skipBreak()")
        if let session = currentSession {
            session.endDate = .now
            session.duration = session.endDate!.timeIntervalSince(session.startDate)
            session.wasCompleted = false
            modelContext?.insert(session)
            try? modelContext?.save()
        }
        isOnBreak = false
        currentSession = nil
    }
}
