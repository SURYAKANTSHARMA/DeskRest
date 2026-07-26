//
//  BreakServiceProtocol.swift
//  DeskReset
//

import Foundation

protocol BreakServiceProtocol: AnyObject {
    var isOnBreak: Bool { get }
    var currentSession: BreakSession? { get }

    func startBreak(type: BreakType) async
    func endBreak() async
    func skipBreak() async
}
