//
//  AppRatingPromptView.swift
//  DeskReset
//
//  Premium macOS modal prompt inviting users to rate DeskReset on the
//  Mac App Store or submit constructive feedback directly to the developer.
//

import SwiftUI
import StoreKit

struct AppRatingPromptView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    // MARK: — State
    @State private var selectedRating: Int = 0
    @State private var hoveredStar: Int = 0
    @State private var hasSubmittedRating: Bool = false
    @State private var appeared: Bool = false

    var onComplete: (() -> Void)? = nil

    private var isHighRating: Bool { selectedRating >= 4 }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.07, green: 0.09, blue: 0.15).ignoresSafeArea()

            // Ambient background glow
            Circle()
                .fill(
                    isHighRating && hasSubmittedRating
                        ? Color.yellow.opacity(0.12)
                        : Color.brandPrimary.opacity(0.12)
                )
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -40)

            VStack(spacing: 20) {
                // Top close button
                HStack {
                    Spacer()
                    Button {
                        handleDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                if !hasSubmittedRating {
                    initialRatingStep
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                } else if isHighRating {
                    positiveRatingStep
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                } else {
                    constructiveFeedbackStep
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }
            }
            .padding(26)
        }
        .frame(width: 440, height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: — Step 1: Initial Star Selection

    private var initialRatingStep: some View {
        VStack(spacing: 16) {
            // Icon Orb
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.3), Color.brandSecondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(Color.brandPrimary.opacity(0.4), lineWidth: 1))

                Image(systemName: "heart.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.35, blue: 0.45), Color.brandPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12)

            // Header text
            VStack(spacing: 6) {
                Text("Enjoying DeskReset?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("How has your posture and wellness journey been so far?")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // Interactive Stars
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    starButton(star)
                }
            }
            .padding(.vertical, 8)

            // Dynamic Star Caption
            Text(starCaption(for: hoveredStar > 0 ? hoveredStar : selectedRating))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(height: 16)
        }
    }

    private func starButton(_ star: Int) -> some View {
        let activeLevel = hoveredStar > 0 ? hoveredStar : selectedRating
        let isFilled = star <= activeLevel

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedRating = star
                hasSubmittedRating = true
            }
            AnalyticsService.shared.log(.ratingSentimentSelected(
                sentiment: star >= 4 ? "positive" : "constructive",
                rating: star
            ))
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(
                    isFilled
                        ? Color(red: 0.99, green: 0.76, blue: 0.18)
                        : Color.white.opacity(0.25)
                )
                .scaleEffect(hoveredStar == star ? 1.2 : (selectedRating == star ? 1.15 : 1.0))
                .shadow(
                    color: isFilled ? Color.yellow.opacity(0.4) : .clear,
                    radius: 8
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredStar = isHovered ? star : 0
            }
        }
    }

    private func starCaption(for rating: Int) -> String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Could be better"
        case 3: return "Good"
        case 4: return "Great!"
        case 5: return "Loving it! ⭐️"
        default: return "Tap a star to rate"
        }
    }

    // MARK: — Step 2A: Positive Sentiment (4-5 Stars)

    private var positiveRatingStep: some View {
        VStack(spacing: 16) {
            // Glowing Trophy / App Store Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.99, green: 0.76, blue: 0.18).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1))

                Image(systemName: "star.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(red: 0.99, green: 0.76, blue: 0.18))
            }
            .shadow(color: Color.yellow.opacity(0.35), radius: 12)

            VStack(spacing: 6) {
                Text("We're thrilled you love it!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("Reviews on the Mac App Store make a huge difference for independent apps. Would you take 30 seconds to rate DeskReset?")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
            }

            VStack(spacing: 10) {
                // Primary App Store Button
                Button {
                    // Trigger Apple native review prompt
                    requestReview()
                    // Open Mac App Store page directly
                    AppRatingService.shared.rateOnAppStore(source: "prompt_positive_button")
                    onComplete?()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Rate on Mac App Store")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.brandPrimary.opacity(0.35), radius: 8, y: 2)
                }
                .buttonStyle(.plain)

                // Maybe Later
                Button {
                    AppRatingService.shared.dismissPrompt(remindLater: true, action: "maybe_later")
                    handleDismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }

    // MARK: — Step 2B: Constructive Sentiment (1-3 Stars)

    private var constructiveFeedbackStep: some View {
        VStack(spacing: 16) {
            // Feedback Envelope Icon
            ZStack {
                Circle()
                    .fill(Color.brandSecondary.opacity(0.18))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(Color.brandSecondary.opacity(0.35), lineWidth: 1))

                Image(systemName: "envelope.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.brandSecondary)
            }
            .shadow(color: Color.brandSecondary.opacity(0.3), radius: 12)

            VStack(spacing: 6) {
                Text("We want to make it better")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("Your experience matters to us. Could you share what didn't meet your expectations? Your feedback directly guides our next updates.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
            }

            VStack(spacing: 10) {
                // Primary Feedback Button
                Button {
                    AppRatingService.shared.openFeedbackEmail(source: "prompt_constructive", starRating: selectedRating)
                    AppRatingService.shared.dismissPrompt(remindLater: false, action: "sent_feedback")
                    onComplete?()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Send Direct Feedback")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.brandSecondary, Color.brandPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.brandSecondary.opacity(0.35), radius: 8, y: 2)
                }
                .buttonStyle(.plain)

                // Dismiss
                Button {
                    AppRatingService.shared.dismissPrompt(remindLater: true, action: "closed_constructive")
                    handleDismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }

    // MARK: — Dismiss Handler

    private func handleDismiss() {
        if !hasSubmittedRating {
            AppRatingService.shared.dismissPrompt(remindLater: true, action: "closed_without_rating")
        }
        onComplete?()
        dismiss()
    }
}

#Preview {
    AppRatingPromptView()
}
