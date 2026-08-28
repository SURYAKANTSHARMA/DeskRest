//
//  LegalView.swift
//  DeskReset
//
//  In-app Privacy Policy and Terms of Use viewer.
//  Required by Apple for apps accessing camera or personal data.
//

import SwiftUI

// MARK: — Legal Document Type

enum LegalDocument: String, CaseIterable {
    case privacyPolicy = "Privacy Policy"
    case termsOfUse    = "Terms of Use"

    var icon: String {
        switch self {
        case .privacyPolicy: return "lock.shield.fill"
        case .termsOfUse:    return "doc.text.fill"
        }
    }

    var lastUpdated: String { "August 2025" }
}

// MARK: — Legal Sheet Wrapper

struct LegalView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DashboardView.navyBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(DashboardView.purpleAccent.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: document.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DashboardView.purpleAccent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(document.rawValue)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(DashboardView.textPrimW)
                        Text("Last updated: \(document.lastUpdated)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DashboardView.textSecW)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(DashboardView.textSecW)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(DashboardView.cardBg)
                .overlay(Rectangle().fill(DashboardView.cardBorder).frame(height: 1), alignment: .bottom)

                // Content
                ScrollView(showsIndicators: true) {
                    Group {
                        switch document {
                        case .privacyPolicy: PrivacyPolicyContent()
                        case .termsOfUse:    TermsOfUseContent()
                        }
                    }
                    .padding(28)
                }
            }
        }
        .frame(minWidth: 560, idealWidth: 640, minHeight: 480, idealHeight: 560)
        .onAppear {
            AnalyticsService.shared.log(.legalDocumentViewed(
                documentName: document == .privacyPolicy ? "privacy_policy" : "terms_of_use"
            ))
        }
    }
}

// MARK: — Privacy Policy Content

private struct PrivacyPolicyContent: View {
    var body: some View {
        LegalDocument_Body(sections: [
            LegalSection(
                title: "Overview",
                body: "DeskReset (\"we\", \"the app\") is committed to protecting your privacy. This Privacy Policy explains how DeskReset handles information when you use our macOS application."
            ),
            LegalSection(
                title: "Camera Access",
                body: "DeskReset requests access to your Mac's camera solely to analyse your posture in real time using Apple's on-device Vision framework.\n\n• Camera frames are processed entirely on your device.\n• No images, video, or biometric data are ever recorded, stored on disk, or transmitted to any server.\n• The camera is only active while you have monitoring enabled.\n• You can revoke camera access at any time in System Settings → Privacy & Security → Camera."
            ),
            LegalSection(
                title: "Data Storage",
                body: "DeskReset stores the following data locally on your Mac only:\n\n• Posture scan scores (numeric values, no images)\n• Break session timestamps\n• Your monitoring preferences and calibration baseline\n\nAll data is stored in a local SwiftData database on your Mac. It never leaves your device."
            ),
            LegalSection(
                title: "Data Sharing",
                body: "We do not share, sell, rent, or transfer any of your data to third parties. DeskReset contains no analytics SDKs, no advertising networks, and no crash-reporting services that transmit data off-device."
            ),
            LegalSection(
                title: "Third-Party Services",
                body: "DeskReset uses only Apple's first-party frameworks:\n\n• Vision (on-device pose estimation)\n• SwiftData (local database)\n• UserNotifications (local posture reminders)\n\nNo third-party SDKs or services are used."
            ),
            LegalSection(
                title: "Notifications",
                body: "DeskReset may send local notifications to remind you to check your posture or take a break. These notifications are generated on-device and are not used to collect any data. You can manage notification permissions in System Settings → Notifications."
            ),
            LegalSection(
                title: "Children's Privacy",
                body: "DeskReset is not directed at children under the age of 13. We do not knowingly collect any personal information from children."
            ),
            LegalSection(
                title: "Changes to This Policy",
                body: "We may update this Privacy Policy from time to time. Any changes will be reflected in an updated version of the app. Continued use of the app after changes constitutes acceptance of the revised policy."
            ),
            LegalSection(
                title: "Contact",
                body: "If you have any questions about this Privacy Policy, please contact:\n\nsupport@deskreset.app"
            ),
        ])
    }
}

// MARK: — Terms of Use Content

private struct TermsOfUseContent: View {
    var body: some View {
        LegalDocument_Body(sections: [
            LegalSection(
                title: "Acceptance of Terms",
                body: "By downloading, installing, or using DeskReset (\"the App\"), you agree to be bound by these Terms of Use. If you do not agree to these terms, do not use the App."
            ),
            LegalSection(
                title: "License",
                body: "DeskReset grants you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial use on Apple-branded devices that you own or control, subject to these Terms and the Apple Media Services Terms and Conditions."
            ),
            LegalSection(
                title: "Health Disclaimer",
                body: "DeskReset is a wellness tool designed to help you become more aware of your posture habits. It is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment.\n\nPosture scores and recommendations are for informational purposes only. Consult a qualified healthcare professional for any medical concerns, pain, or physical conditions."
            ),
            LegalSection(
                title: "Accuracy of Analysis",
                body: "Posture analysis is performed using computer vision on-device. Accuracy may vary depending on camera placement, lighting conditions, clothing, distance from camera, and other environmental factors. Results are estimates, not clinical measurements."
            ),
            LegalSection(
                title: "Intellectual Property",
                body: "All content, design, code, and assets in DeskReset are the intellectual property of DeskReset and are protected by applicable copyright and intellectual property laws. You may not copy, modify, distribute, or reverse-engineer any part of the App."
            ),
            LegalSection(
                title: "Disclaimer of Warranties",
                body: "The App is provided \"AS IS\" and \"AS AVAILABLE\" without any warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, or non-infringement."
            ),
            LegalSection(
                title: "Limitation of Liability",
                body: "To the maximum extent permitted by applicable law, DeskReset and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly."
            ),
            LegalSection(
                title: "Changes to Terms",
                body: "We reserve the right to modify these Terms at any time. Changes will be reflected in an updated version of the App. Continued use of the App after changes constitutes acceptance of the revised Terms."
            ),
            LegalSection(
                title: "Governing Law",
                body: "These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions."
            ),
            LegalSection(
                title: "Contact",
                body: "Questions about these Terms? Contact us at:\n\nsupport@deskreset.app"
            ),
        ])
    }
}

// MARK: — Shared Layout Helpers

private struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct LegalDocument_Body: View {
    let sections: [LegalSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DashboardView.textPrimW)

                    Text(section.body)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundStyle(DashboardView.textSecW)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DashboardView.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DashboardView.cardBorder, lineWidth: 1))
                )
            }
        }
    }
}

// MARK: — Preview

#Preview {
    LegalView(document: .privacyPolicy)
}
