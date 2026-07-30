//
//  ShapeStyle+DeskReset.swift
//  DeskReset
//
//  Extends ShapeStyle so all Color aliases work with dot-syntax.
//  Values stay in sync with Color+DeskReset.swift.
//

import SwiftUI
import AppKit

extension ShapeStyle where Self == Color {

    // MARK: - Adaptive Brand Colors (Purple Primary + Cyan Accent)
    static var brandPrimary: Color   { Color.brandPrimary }
    static var brandSecondary: Color { Color.brandSecondary }
    static var brandAccent: Color    { Color.brandAccent }

    // MARK: - Adaptive Card Surface & Border Tokens
    static var drCardBackground: Color     { Color.drCardBackground }
    static var drCardBorder: Color         { Color.drCardBorder }
    static var drIconTileBackground: Color { Color.drIconTileBackground }
    static var drInnerBoxBackground: Color { Color.drInnerBoxBackground }

    // MARK: - Surfaces
    static var surfacePrimary: Color   { Color(nsColor: .windowBackgroundColor) }
    static var surfaceSecondary: Color { Color(nsColor: .controlBackgroundColor) }
    static var surfaceTertiary: Color  { Color(nsColor: .underPageBackgroundColor) }

    // MARK: - Text
    static var textPrimary: Color   { Color(nsColor: .labelColor) }
    static var textSecondary: Color { Color(nsColor: .secondaryLabelColor) }
    static var textTertiary: Color  { Color(nsColor: .tertiaryLabelColor) }

    // MARK: - Status
    static var statusSuccess: Color { Color(red: 16/255,  green: 185/255, blue: 129/255) } // #10B981
    static var statusWarning: Color { Color(red: 245/255, green: 158/255, blue: 11/255)  } // #F59E0B
    static var statusError: Color   { Color(red: 239/255, green: 68/255,  blue: 68/255)  } // #EF4444
    static var statusInfo: Color    { Color.brandSecondary }
    static var statusNeutral: Color { Color(nsColor: .systemGray) }

    // MARK: - Posture Score Tiers
    static var scoreExcellent: Color { Color.scoreExcellent }
    static var scoreGood: Color      { Color.scoreGood }
    static var scoreFair: Color      { Color.scoreFair }
    static var scorePoor: Color      { Color.scorePoor }

    // MARK: - Break types
    static var breakMicro: Color { Color.breakMicro }
    static var breakShort: Color { Color.breakShort }
    static var breakLong: Color  { Color.breakLong }
}
