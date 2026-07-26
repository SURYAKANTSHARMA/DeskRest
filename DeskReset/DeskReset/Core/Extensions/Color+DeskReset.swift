//
//  Color+DeskReset.swift
//  DeskReset
//
//  Brand + semantic color palette. All values adapt automatically to Dark Mode
//  using macOS NSColor semantic APIs.
//

import SwiftUI

extension Color {

    // MARK: - Brand
    /// Primary brand tint — indigo that feels calm and focused.
    static let brandPrimary   = Color.indigo
    static let brandSecondary = Color.purple
    static let brandAccent    = Color.cyan

    // MARK: - Backgrounds (auto-adaptive)
    static let surfacePrimary   = Color(nsColor: .windowBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .controlBackgroundColor)
    static let surfaceTertiary  = Color(nsColor: .underPageBackgroundColor)

    // MARK: - Text (auto-adaptive)
    static let textPrimary   = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary  = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Status
    static let statusSuccess = Color.green
    static let statusWarning = Color.orange
    static let statusError   = Color.red
    static let statusInfo    = Color.blue
    static let statusNeutral = Color(nsColor: .systemGray)

    // MARK: - Break Types
    static let breakMicro = Color.cyan
    static let breakShort = Color.green
    static let breakLong  = Color.indigo
}
