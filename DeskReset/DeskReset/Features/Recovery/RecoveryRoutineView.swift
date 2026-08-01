//
//  RecoveryRoutineView.swift
//  DeskReset
//
//  Premium Ergonomic Recovery Routine sheet — purple/cyan glassmorphic design.
//  Presents structured ergonomic exercises, workplace safety notes, and strict
//  non-medical guardrails.
//

import SwiftUI
import SwiftData

struct RecoveryRoutineView: View {

    let routine: ErgonomicRecoveryRoutine
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var completedExerciseIDs: Set<String> = []
    @State private var headerAppeared  = false
    @State private var contentAppeared = false

    private var completionRatio: Double {
        guard !routine.exercises.isEmpty else { return 0 }
        return Double(completedExerciseIDs.count) / Double(routine.exercises.count)
    }

    private var allComplete: Bool { completedExerciseIDs.count == routine.exercises.count }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            Circle()
                .fill(Color.brandPrimary.opacity(colorScheme == .dark ? 0.15 : 0.08))
                .frame(width: 500, height: 500)
                .blur(radius: 110)
                .offset(x: -80, y: -60)
            Circle()
                .fill(Color.brandSecondary.opacity(colorScheme == .dark ? 0.12 : 0.06))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 200, y: 160)

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────
                headerBar
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -14)

                Divider()
                    .opacity(0.4)

                // ── Progress Bar (below divider) ─────────────────────────
                completionBar
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                    .opacity(contentAppeared ? 1 : 0)

                // ── Scrollable content ───────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        explanationCard
                        exercisesSection
                        safetyNotesCard
                        disclaimerFooter
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 22)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)

                Divider()
                    .opacity(0.4)
                bottomActionBar
            }
        }
        .frame(minWidth: 560, minHeight: 560)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                headerAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                contentAppeared = true
            }
        }
    }

    // MARK: — Header Bar

    private var headerBar: some View {
        HStack(spacing: 14) {
            // Icon orb
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPrimary.opacity(0.25), Color.brandSecondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(Color.brandPrimary.opacity(0.3), lineWidth: 1))
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.brandPrimary, Color.brandSecondary],
                                       startPoint: .top, endPoint: .bottom)
                    )
            }
            .shadow(color: Color.brandPrimary.opacity(0.25), radius: 8)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Ergonomic Recovery")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.textPrimary)

                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9, weight: .bold))
                        Text(routine.totalDuration)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.brandPrimary.opacity(0.10), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.brandPrimary.opacity(0.25), lineWidth: 1))
                }

                Text("Target: \(routine.detectedIssue)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    // MARK: — Completion Progress Bar

    private var completionBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(allComplete ? Color.statusSuccess : Color.brandPrimary)
                    Text(allComplete ? "Routine Complete!" : "\(completedExerciseIDs.count) of \(routine.exercises.count) exercises done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(allComplete ? Color.statusSuccess : .textSecondary)
                }
                Spacer()
                Text("\(Int(completionRatio * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(allComplete ? Color.statusSuccess : Color.brandPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.brandPrimary.opacity(0.10))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: allComplete
                                    ? [Color.statusSuccess.opacity(0.8), Color.statusSuccess]
                                    : [Color.brandPrimary, Color.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * completionRatio, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionRatio)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(Color.drCardBackground, in: RoundedRectangle(cornerRadius: 12))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
            allComplete ? Color.statusSuccess.opacity(0.3) : Color.drGlassSpecularBorder, lineWidth: 1
        ))
    }

    // MARK: — Explanation Card

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.statusWarning.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.statusWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ERGONOMIC INSIGHT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.statusWarning.opacity(0.8))
                    .tracking(0.5)
                Text(routine.explanation)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.statusWarning.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.statusWarning.opacity(0.22), lineWidth: 1))
    }

    // MARK: — Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.brandPrimary)
                Text("RECOMMENDED EXERCISES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.textTertiary)
                    .tracking(0.8)
                Spacer()
                Text("\(completedExerciseIDs.count)/\(routine.exercises.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(completedExerciseIDs.count == routine.exercises.count ? Color.statusSuccess : Color.brandPrimary)
            }

            ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseRow(index: index + 1, exercise: exercise)
            }
        }
    }

    private func exerciseRow(index: Int, exercise: ErgonomicExercise) -> some View {
        let isDone = completedExerciseIDs.contains(exercise.id)

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                if isDone {
                    completedExerciseIDs.remove(exercise.id)
                } else {
                    completedExerciseIDs.insert(exercise.id)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .fill(isDone ? Color.statusSuccess.opacity(0.15) : Color.drIconTileBackground)
                        .frame(width: 28, height: 28)
                    Circle()
                        .strokeBorder(isDone ? Color.statusSuccess.opacity(0.4) : Color.brandPrimary.opacity(0.25), lineWidth: 1)
                        .frame(width: 28, height: 28)
                    Image(systemName: isDone ? "checkmark" : "\(index)")
                        .font(.system(size: isDone ? 11 : 10, weight: .bold))
                        .foregroundStyle(isDone ? Color.statusSuccess : Color.brandPrimary)
                }

                // Exercise details
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(exercise.title)
                            .font(.system(size: 13.5, weight: .semibold))
                            .strikethrough(isDone, color: .textSecondary)
                            .foregroundStyle(isDone ? Color.textSecondary : Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        // Duration badge
                        Text(exercise.duration)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.brandSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandSecondary.opacity(0.10), in: Capsule())
                    }

                    // Muscle + rep pills
                    HStack(spacing: 7) {
                        Label(exercise.targetMuscle, systemImage: "target")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.brandPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandPrimary.opacity(0.10), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.brandPrimary.opacity(0.2), lineWidth: 1))

                        Label(exercise.repetitions, systemImage: "repeat")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.brandSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandSecondary.opacity(0.10), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.brandSecondary.opacity(0.2), lineWidth: 1))
                    }

                    Text(exercise.instructions)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(isDone ? Color.textTertiary : Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
            .padding(14)
            .background(
                isDone
                    ? Color.statusSuccess.opacity(0.05)
                    : Color.drCardBackground,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isDone
                            ? Color.statusSuccess.opacity(0.3)
                            : Color.drGlassSpecularBorder,
                        lineWidth: isDone ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: isDone ? Color.statusSuccess.opacity(0.08) : .clear,
                radius: 6, y: 2
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isDone ? 0.995 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDone)
    }

    // MARK: — Safety Notes Card

    private var safetyNotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "shield.badge.exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.statusWarning)
                Text("WORKPLACE SAFETY & COMFORT")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(Color.statusWarning)
                    .tracking(0.5)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(routine.safetyNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(Color.statusWarning.opacity(0.7))
                            .padding(.top, 5)
                        Text(note)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusWarning.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.statusWarning.opacity(0.2), lineWidth: 1))
    }

    // MARK: — Disclaimer Footer

    private var disclaimerFooter: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.brandPrimary.opacity(0.5))
                .padding(.top, 1)
            Text(routine.disclaimer)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    // MARK: — Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Dismiss button (glass style)
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("Dismiss")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.textSecondary)
                .frame(width: 110)
                .padding(.vertical, 10)
                .background(Color.drCardBackground, in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.drGlassSpecularBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Complete button (gradient style)
            Button {
                onComplete?()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: allComplete ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.white.opacity(0.9), .white],
                                           startPoint: .top, endPoint: .bottom)
                        )
                    Text(allComplete ? "Complete Routine ✓" : "Mark Complete & Log Break")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: allComplete
                            ? [Color.statusSuccess.opacity(0.9), Color.statusSuccess]
                            : [Color.brandPrimary, Color.brandSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .overlay(
                    Capsule().strokeBorder(
                        allComplete ? Color.statusSuccess.opacity(0.5) : Color.brandPrimary.opacity(0.3),
                        lineWidth: 1
                    )
                )
                .shadow(
                    color: allComplete ? Color.statusSuccess.opacity(0.3) : Color.brandPrimary.opacity(0.35),
                    radius: 8, y: 3
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.3), value: allComplete)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }
}

#Preview {
    RecoveryRoutineView(
        routine: ErgonomicRecoveryRoutine(
            detectedIssue: "Forward Head Posture",
            explanation: "Sustained forward head positioning increases effective head weight on neck flexors.",
            exercises: [
                ErgonomicExercise(
                    title: "Chin Retraction & Tuck",
                    instructions: "Sit upright, look straight ahead, gently pull head backward while maintaining eye level. Hold at end range.",
                    repetitions: "5 reps • 5-second hold",
                    targetMuscle: "Deep Neck Flexors",
                    duration: "45s"
                ),
                ErgonomicExercise(
                    title: "Thoracic Extension Stretch",
                    instructions: "Interlace fingers behind your head, gently extend your upper back over your chair edge.",
                    repetitions: "3 reps • 10-second hold",
                    targetMuscle: "Thoracic Spine",
                    duration: "60s"
                )
            ],
            totalDuration: "2 minutes",
            safetyNotes: ["Perform all movements in a comfortable, pain-free range.", "Stop if you feel any sharp pain or discomfort."]
        )
    )
}
