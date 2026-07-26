//
//  ShapeStyle+DeskReset.swift
//  DeskReset
//
//  Extends ShapeStyle so our Color aliases can be used with dot-syntax
//  in foregroundStyle(), background(), etc.
//

import SwiftUI

extension ShapeStyle where Self == Color {

    // MARK: - Brand
    static var brandPrimary: Color   { .indigo }
    static var brandSecondary: Color { .purple }
    static var brandAccent: Color    { .cyan }

    // MARK: - Surfaces
    static var surfacePrimary: Color   { Color(nsColor: .windowBackgroundColor) }
    static var surfaceSecondary: Color { Color(nsColor: .controlBackgroundColor) }
    static var surfaceTertiary: Color  { Color(nsColor: .underPageBackgroundColor) }

    // MARK: - Text
    static var textPrimary: Color   { Color(nsColor: .labelColor) }
    static var textSecondary: Color { Color(nsColor: .secondaryLabelColor) }
    static var textTertiary: Color  { Color(nsColor: .tertiaryLabelColor) }

    // MARK: - Status
    static var statusSuccess: Color { .green }
    static var statusWarning: Color { .orange }
    static var statusError: Color   { .red }
    static var statusInfo: Color    { .blue }
    static var statusNeutral: Color { Color(nsColor: .systemGray) }

    // MARK: - Break types
    static var breakMicro: Color { .cyan }
    static var breakShort: Color { .green }
    static var breakLong: Color  { .indigo }
}
