//
//  TimerServiceProtocol.swift
//  DeskReset
//

import Foundation

protocol TimerServiceProtocol: AnyObject {
    var isRunning: Bool { get }
    var remainingSeconds: Int { get }
    var totalSeconds: Int { get }
    /// 0.0 → 1.0 representing elapsed / total.
    var progress: Double { get }

    func start(duration: TimeInterval)
    func pause()
    func resume()
    func stop()
    func reset()
}
