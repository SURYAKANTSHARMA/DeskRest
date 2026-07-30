//
//  Color+DeskReset.swift
//  DeskReset
//
//  Adaptive Design System (Light & Dark Mode Intensity System)
//  Light Mode: Rich Royal Violet (#6D28D9) & Ocean Cyan (#0284C7) for 100% legibility and zero glare.
//  Dark Mode: Electric Amethyst (#7C3AED) & Soft Sky Cyan (#38BDF8) for glowing neon depth.
//

import SwiftUI
import AppKit

extension Color {

    // MARK: - Adaptive Brand Colors (Light & Dark Intensity Providers)

    /// Adaptive Primary Purple: Deep Royal Violet (#6D28D9) in Light Mode, Electric Amethyst (#7C3AED) in Dark Mode.
    static let brandPrimary = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor(red: 109/255, green: 40/255, blue: 217/255, alpha: 1.0)  // #6D28D9 Deep Royal Violet
            : NSColor(red: 124/255, green: 58/255, blue: 237/255, alpha: 1.0)  // #7C3AED Electric Amethyst
    }))

    /// Adaptive Secondary Cyan: Ocean Cyan (#0284C7) in Light Mode, Aurora Cyan (#06B6D4) in Dark Mode.
    static let brandSecondary = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor(red: 2/255,   green: 132/255, blue: 199/255, alpha: 1.0) // #0284C7 Ocean Cyan
            : NSColor(red: 6/255,   green: 182/255, blue: 212/255, alpha: 1.0) // #06B6D4 Aurora Cyan
    }))

    /// Adaptive Cyan Accent: Deep Cyan (#0369A1) in Light Mode, Soft Sky Cyan (#38BDF8) in Dark Mode.
    static let brandAccent = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor(red: 3/255,   green: 105/255, blue: 161/255, alpha: 1.0) // #0369A1 Deep Sky Cyan
            : NSColor(red: 56/255,  green: 189/255, blue: 248/255, alpha: 1.0) // #38BDF8 Soft Sky Cyan
    }))

    // MARK: - Adaptive Card Surface & Glassmorphic Tokens (Light & Dark Mode)

    /// Translucent glassmorphic card background: 85% white in Light Mode, 55% Dark Slate (#1A1C23) in Dark Mode.
    static let drCardBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor.white.withAlphaComponent(0.85)
            : NSColor(red: 26/255, green: 28/255, blue: 35/255, alpha: 0.55)
    }))

    /// Specular glass card border: Subtle dark stroke in Light Mode, White @ 12% in Dark Mode.
    static let drCardBorder = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor.black.withAlphaComponent(0.08)
            : NSColor.white.withAlphaComponent(0.12)
    }))

    /// Specular highlight gradient stroke for glass edges.
    static let drGlassSpecularBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.35),
            Color.brandPrimary.opacity(0.20),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Adaptive squircle icon container tile: Light Purple tint in Light Mode, Translucent in Dark Mode.
    static let drIconTileBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor(red: 109/255, green: 40/255, blue: 217/255, alpha: 0.08)
            : NSColor.white.withAlphaComponent(0.08)
    }))

    /// Adaptive inner box container: Subtle grey tint in Light Mode, Dark translucent in Dark Mode.
    static let drInnerBoxBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        let isLight = appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
        return isLight
            ? NSColor.black.withAlphaComponent(0.04)
            : NSColor.white.withAlphaComponent(0.04)
    }))

    // MARK: - Backgrounds (auto-adaptive via NSColor)
    static let surfacePrimary   = Color(nsColor: .windowBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .controlBackgroundColor)
    static let surfaceTertiary  = Color(nsColor: .underPageBackgroundColor)

    // MARK: - Text (auto-adaptive via NSColor)
    static let textPrimary   = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary  = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Status
    static let statusSuccess = Color(red: 16/255,  green: 185/255, blue: 129/255) // #10B981 emerald
    static let statusWarning = Color(red: 245/255, green: 158/255, blue: 11/255)  // #F59E0B amber
    static let statusError   = Color(red: 239/255, green: 68/255,  blue: 68/255)  // #EF4444 red
    static let statusInfo    = Color.brandSecondary
    static let statusNeutral = Color(nsColor: .systemGray)

    // MARK: - Posture Score Color Ramp (Adaptive)

    /// Score 85–100: Excellent — adaptive cyan.
    static let scoreExcellent = Color.brandAccent
    /// Score 65–84: Good — adaptive purple.
    static let scoreGood      = Color.brandPrimary
    /// Score 40–64: Fair — warm amber.
    static let scoreFair      = Color(red: 245/255, green: 158/255, blue: 11/255) // #F59E0B
    /// Score 0–39: Poor — soft red.
    static let scorePoor      = Color(red: 239/255, green: 68/255,  blue: 68/255) // #EF4444

    /// Returns the correct score-tier color for a given posture score (0–100).
    static func postureScoreColor(for score: Int) -> Color {
        switch score {
        case 85...100: return .scoreExcellent
        case 65..<85:  return .scoreGood
        case 40..<65:  return .scoreFair
        default:       return .scorePoor
        }
    }

    // MARK: - Break Types
    static let breakMicro = Color.brandSecondary
    static let breakShort = Color(red: 16/255,  green: 185/255, blue: 129/255) // emerald
    static let breakLong  = Color.brandPrimary

    // MARK: - Brand Gradient (Adaptive Purple to Cyan)
    static let brandGradientColors: [Color] = [
        Color.brandPrimary,
        Color.brandSecondary
    ]
}
