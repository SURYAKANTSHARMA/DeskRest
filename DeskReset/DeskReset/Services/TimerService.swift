//
//  TimerService.swift
//  DeskReset
//
//  Placeholder implementation — timer logic not yet implemented.
//

import Foundation
import Observation
import OSLog

@Observable
final class TimerService: TimerServiceProtocol {

    // MARK: - State
    var isRunning: Bool  = false
    var remainingSeconds: Int = 0
    var totalSeconds: Int = 0

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    // MARK: - Actions

    func start(duration: TimeInterval) {
        // TODO: Implement countdown timer using Swift Concurrency / Clock API
        Logger.timer.info("TimerService.start(duration: \(duration))")
        totalSeconds    = Int(duration)
        remainingSeconds = Int(duration)
        isRunning       = true
    }

    func pause() {
        // TODO: Implement pause
        Logger.timer.info("TimerService.pause()")
        isRunning = false
    }

    func resume() {
        // TODO: Implement resume
        Logger.timer.info("TimerService.resume()")
        isRunning = true
    }

    func stop() {
        // TODO: Implement stop
        Logger.timer.info("TimerService.stop()")
        isRunning        = false
        remainingSeconds = 0
    }

    func reset() {
        // TODO: Implement reset
        Logger.timer.info("TimerService.reset()")
        isRunning        = false
        remainingSeconds = totalSeconds
    }
}
