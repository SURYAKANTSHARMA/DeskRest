//
//  BreakSession.swift
//  DeskReset
//
//  SwiftData model representing a single recorded break session.
//

import Foundation
import SwiftData

// MARK: — Break Type

enum BreakType: String, Codable, CaseIterable, Identifiable {
    case micro = "Micro"   // ~90s  — eye rest
    case short = "Short"   // ~5min — stretch
    case long  = "Long"    // ~15min — walk/reset

    var id: String { rawValue }

    var defaultDuration: TimeInterval {
        switch self {
        case .micro: return 90
        case .short: return 300
        case .long:  return 900
        }
    }

    var icon: String {
        switch self {
        case .micro: return "eye.slash"
        case .short: return "figure.walk"
        case .long:  return "figure.yoga"
        }
    }

    var color: String {
        switch self {
        case .micro: return "breakMicro"
        case .short: return "breakShort"
        case .long:  return "breakLong"
        }
    }

    var label: String { rawValue + " Break" }
}

// MARK: — BreakSession Model

@Model
final class BreakSession {

    var id: UUID
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
    /// Stored as raw string to avoid @Model + Codable enum edge-cases.
    var breakTypeRaw: String
    var wasCompleted: Bool
    var notes: String

    // MARK: Derived
    var breakType: BreakType {
        BreakType(rawValue: breakTypeRaw) ?? .short
    }

    var displayDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }

    // MARK: Init
    init(
        startDate: Date = .now,
        breakType: BreakType = .short,
        wasCompleted: Bool = false,
        notes: String = ""
    ) {
        self.id           = UUID()
        self.startDate    = startDate
        self.endDate      = nil
        self.duration     = 0
        self.breakTypeRaw = breakType.rawValue
        self.wasCompleted = wasCompleted
        self.notes        = notes
    }
}
