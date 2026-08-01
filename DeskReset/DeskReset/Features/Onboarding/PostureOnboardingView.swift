//
//  PostureOnboardingView.swift
//  DeskReset
//
//  4-step first-launch onboarding guide with AI-generated hero images:
//  Step 1 — Welcome to DeskReset
//  Step 2 — 7-Point Ideal Posture Guide
//  Step 3 — Camera Positioning Tips
//  Step 4 — Calibrate Now
//

import SwiftUI

// MARK: — Onboarding Step

private enum OnboardingStep: Int, CaseIterable {
    case welcome       = 0
    case posture       = 1
    case camera        = 2
    case calibrate     = 3

    var title: String {
        switch self {
        case .welcome:   return "Welcome to DeskReset"
        case .posture:   return "Your Ideal Posture"
        case .camera:    return "Camera Positioning"
        case .calibrate: return "Set Your Baseline"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your AI-powered posture & wellness companion. Let's get you set up in 3 quick steps."
        case .posture:
            return "Follow these 7 checkpoints to sit ergonomically. DeskReset monitors you against this ideal."
        case .camera:
            return "Position your camera correctly so Vision AI can detect your posture accurately."
        case .calibrate:
            return "Sit in your best posture and calibrate — this sets your personal healthy baseline."
        }
    }

    /// Name of the AI-generated image in Assets.xcassets
    var imageName: String {
        switch self {
        case .welcome:   return "OnboardingWelcome"
        case .posture:   return "OnboardingPosture"
        case .camera:    return "OnboardingCamera"
        case .calibrate: return "OnboardingCalibrate"
        }
    }

    var accentColor: Color {
        switch self {
        case .welcome:   return .brandPrimary
        case .posture:   return .brandAccent
        case .camera:    return .brandSecondary
        case .calibrate: return .brandPrimary
        }
    }
}

// MARK: — Posture Checkpoint

private struct PostureCheckpoint: Identifiable {
    let id = UUID()
    let number: Int
    let label: String
    let description: String
    let icon: String
    let color: Color
}

private let postureCheckpoints: [PostureCheckpoint] = [
    PostureCheckpoint(number: 1, label: "Head",       description: "Ears aligned with shoulders. Eyes level with top third of screen.",       icon: "person.fill",                    color: Color.brandPrimary),
    PostureCheckpoint(number: 2, label: "Neck",       description: "Neutral, not tilted forward or back. Avoid \"tech neck\".",                icon: "arrow.up.and.down",              color: Color.brandAccent),
    PostureCheckpoint(number: 3, label: "Shoulders",  description: "Relaxed and level. Not hunched or elevated toward ears.",                  icon: "figure.arms.open",               color: Color.brandPrimary),
    PostureCheckpoint(number: 4, label: "Back",       description: "Lower back supported. Maintain the natural S-curve — no slouching.",       icon: "figure.seated.side",             color: Color.brandAccent),
    PostureCheckpoint(number: 5, label: "Elbows",     description: "Bent ~90°. Wrists neutral, not bent up or down while typing.",             icon: "hand.raised.fill",               color: Color.brandPrimary),
    PostureCheckpoint(number: 6, label: "Hips & Legs",description: "Knees at ~90°. Feet flat on floor. Thighs parallel to the ground.",       icon: "figure.walk.circle.fill",        color: Color.brandAccent),
    PostureCheckpoint(number: 7, label: "Screen",     description: "Arm's length away (~50–70 cm). Top of screen at or just below eye level.", icon: "display",                        color: Color.brandPrimary),
]

// MARK: — Camera Tip

private struct CameraTip: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let description: String
    let isGood: Bool
}

private let cameraTips: [CameraTip] = [
    CameraTip(icon: "checkmark.circle.fill", label: "Centered",        description: "Camera centered directly in front of your face.", isGood: true),
    CameraTip(icon: "checkmark.circle.fill", label: "Full face visible", description: "Head, neck and both shoulders in frame.",         isGood: true),
    CameraTip(icon: "checkmark.circle.fill", label: "Good lighting",   description: "Face well lit from front — avoid backlit setups.", isGood: true),
    CameraTip(icon: "xmark.circle.fill",     label: "Side angles",     description: "Don't sit at an angle to the camera.",            isGood: false),
    CameraTip(icon: "xmark.circle.fill",     label: "Obstructed",      description: "Keep face clear — no objects in front.",          isGood: false),
    CameraTip(icon: "xmark.circle.fill",     label: "Too far away",    description: "Sit within ~80 cm — too far reduces accuracy.",   isGood: false),
]

// MARK: — Main Onboarding View

struct PostureOnboardingView: View {

    @Environment(ServiceLocator.self) private var serviceLocator
    var onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .welcome
    @State private var animateHero = false
    @State private var contentOpacity: Double = 1.0
    @State private var slideOffset: CGFloat = 0

    private var stepIndex: Int { currentStep.rawValue }
    private var isLastStep: Bool { currentStep == .calibrate }

    var body: some View {
        ZStack {
            // ── Layered ambient background ──
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            Circle()
                .fill(currentStep.accentColor.opacity(0.12))
                .frame(width: 600, height: 600)
                .blur(radius: 120)
                .offset(x: -100, y: -80)
                .animation(.easeInOut(duration: 0.8), value: currentStep)
            Circle()
                .fill(Color.brandSecondary.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: 220, y: 180)

            HStack(spacing: 0) {

                // ── LEFT: Hero image panel ──
                heroPanel
                    .frame(width: 280)

                // ── DIVIDER ──
                Rectangle()
                    .fill(Color.drGlassSpecularBorder)
                    .frame(width: 1)

                // ── RIGHT: Content panel ──
                VStack(spacing: 0) {
                    progressPips
                        .padding(.top, 28)
                        .padding(.horizontal, 28)

                    contentPanel
                        .opacity(contentOpacity)
                        .offset(x: slideOffset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    navigationRow
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 800, height: 560)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateHero = true
            }
        }
    }

    // MARK: — Hero Image Panel

    private var heroPanel: some View {
        ZStack {
            // Subtle gradient overlay behind image
            LinearGradient(
                colors: [currentStep.accentColor.opacity(0.18), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.6), value: currentStep)

            // AI-generated hero image
            Image(currentStep.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 280)
                .clipped()
                .opacity(animateHero ? 1.0 : 0.0)
                .scaleEffect(animateHero ? 1.0 : 1.04)
                .animation(.easeOut(duration: 0.7), value: currentStep)
                .animation(.easeOut(duration: 0.6), value: animateHero)

            // Bottom label tag
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("AI Vision · DeskReset")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                .padding(.bottom, 18)
            }
        }
        .background(Color.black.opacity(0.15))
    }

    // MARK: — Progress Pips

    private var progressPips: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= stepIndex ? currentStep.accentColor : currentStep.accentColor.opacity(0.18))
                    .frame(width: step == currentStep ? 28 : 8, height: 8)
                    .animation(.spring(duration: 0.4), value: currentStep)
            }
        }
    }

    // MARK: — Content Panel

    @ViewBuilder
    private var contentPanel: some View {
        switch currentStep {
        case .welcome:   welcomeContent
        case .posture:   postureContent
        case .camera:    cameraContent
        case .calibrate: calibrateContent
        }
    }

    // MARK: — Step 1: Welcome

    private var welcomeContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                stepHeader(step: .welcome)

                VStack(spacing: 10) {
                    featureRow(icon: "camera.viewfinder",  label: "Vision AI Monitoring",    color: .brandPrimary,   detail: "Real-time posture detection via your camera")
                    featureRow(icon: "chart.bar.fill",     label: "Daily Wellness Scores",   color: .brandAccent,    detail: "Track posture trends over your workday")
                    featureRow(icon: "figure.walk",        label: "Smart Break Reminders",   color: .statusSuccess,  detail: "Guided recovery routines to reset stiffness")
                    featureRow(icon: "sparkles",           label: "AI Ergonomic Advisor",    color: .brandSecondary, detail: "Personalised tips based on your posture data")
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
    }

    private func featureRow(icon: String, label: String, color: Color, detail: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.13))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .padding(11)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    // MARK: — Step 2: Posture Guide

    private var postureContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(step: .posture)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 7) {
                    ForEach(postureCheckpoints) { checkpoint in
                        postureCheckpointRow(checkpoint)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    private func postureCheckpointRow(_ c: PostureCheckpoint) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(c.color.opacity(0.15))
                    .frame(width: 26, height: 26)
                Text("\(c.number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(c.color)
            }
            Image(systemName: c.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(c.color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.textPrimary)
                Text(c.description)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 10))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    // MARK: — Step 3: Camera Tips

    private var cameraContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                stepHeader(step: .camera)

                HStack(alignment: .top, spacing: 10) {
                    tipColumn(title: "✓  Do This", tips: cameraTips.filter { $0.isGood }, borderColor: .statusSuccess)
                    tipColumn(title: "✗  Avoid",   tips: cameraTips.filter { !$0.isGood }, borderColor: .statusError)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
    }

    private func tipColumn(title: String, tips: [CameraTip], borderColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(borderColor)
                .padding(.leading, 4)

            ForEach(tips) { tip in
                HStack(spacing: 8) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(tip.isGood ? Color.statusSuccess : Color.statusError)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tip.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text(tip.description)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(borderColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(borderColor.opacity(0.2), lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: — Step 4: Calibrate

    private var calibrateContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                stepHeader(step: .calibrate)

                VStack(spacing: 9) {
                    calibrateRow(number: 1, text: "Sit in your ideal posture — back straight, shoulders level, head neutral.")
                    calibrateRow(number: 2, text: "Make sure your face and both shoulders are visible in the camera frame.")
                    calibrateRow(number: 3, text: "Stay still for 10 seconds while DeskReset records your healthy baseline.")
                }

                // Cue card
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Color.brandPrimary.opacity(0.12)).frame(width: 50, height: 50)
                        Image(systemName: "scope")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ready to calibrate?")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        Text("Click \"Start DeskReset\" — then tap Calibrate Posture on the dashboard.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(Color.brandPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.brandPrimary.opacity(0.22), lineWidth: 1))
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
    }

    private func calibrateRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.brandPrimary.opacity(0.15)).frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandPrimary)
            }
            Text(text)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 11))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
    }

    // MARK: — Shared step header

    private func stepHeader(step: OnboardingStep) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Step label badge
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                Text("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
                    .font(.system(size: 10.5, weight: .bold))
            }
            .foregroundStyle(step.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(step.accentColor.opacity(0.10), in: Capsule())
            .overlay(Capsule().strokeBorder(step.accentColor.opacity(0.25), lineWidth: 1))

            Text(step.title)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.textPrimary)

            Text(step.subtitle)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: — Navigation Row

    private var navigationRow: some View {
        HStack {
            // Back button
            if currentStep != .welcome {
                Button {
                    navigateTo(stepIndex - 1)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(Color.drCardBackground, in: Capsule())
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Skip
            if !isLastStep {
                Button("Skip Setup") {
                    onComplete()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.textTertiary)
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }

            // Next / Finish
            Button {
                if isLastStep {
                    onComplete()
                } else {
                    navigateTo(stepIndex + 1)
                }
            } label: {
                HStack(spacing: 7) {
                    Text(isLastStep ? "Start DeskReset" : "Next")
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: isLastStep ? "checkmark" : "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(currentStep.accentColor, in: Capsule())
                .shadow(color: currentStep.accentColor.opacity(0.45), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
    }

    // MARK: — Navigation helper

    private func navigateTo(_ index: Int) {
        guard let target = OnboardingStep(rawValue: index) else { return }
        let forward = index > stepIndex
        withAnimation(.spring(duration: 0.35)) {
            slideOffset = forward ? 30 : -30
            contentOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            currentStep = target
            slideOffset = forward ? -30 : 30
            withAnimation(.spring(duration: 0.35)) {
                slideOffset = 0
                contentOpacity = 1.0
            }
        }
    }
}
