//
//  RecoveryRoutineView.swift
//  DeskReset
//
//  Displays a generated strongly typed ErgonomicRecoveryRoutine.
//  Presents structured ergonomic exercises, workplace safety notes, and strict non-medical guardrails.
//

import SwiftUI
import SwiftData

struct RecoveryRoutineView: View {

    let routine: ErgonomicRecoveryRoutine
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var completedExerciseIDs: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Ergonomic Explanation Banner
                    explanationCard

                    // 2. Structured Exercises Section
                    exercisesSection

                    // 3. Safety Notes Callout
                    safetyNotesCard

                    // 4. Non-Medical Guardrail Disclaimer
                    disclaimerFooter
                }
                .padding(22)
            }

            Divider()
            bottomActionBar
        }
        .frame(minWidth: 540, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: — Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "figure.walk.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.brandPrimary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Ergonomic Recovery Routine")
                        .font(.headline)
                    Text(routine.totalDuration)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.brandPrimary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.brandPrimary)
                }
                Text("Targeted issue: \(routine.detectedIssue)")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: — Explanation Card

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Ergonomic Insight")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.textSecondary)
                Text(routine.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.textPrimary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.statusWarning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: — Exercises Section

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("RECOMMENDED EXERCISES")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.textTertiary)
                    .tracking(1)

                Spacer()

                Text("\(completedExerciseIDs.count) of \(routine.exercises.count) completed")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.textSecondary)
            }

            ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                exerciseRow(index: index + 1, exercise: exercise)
            }
        }
    }

    private func exerciseRow(index: Int, exercise: ErgonomicExercise) -> some View {
        let isDone = completedExerciseIDs.contains(exercise.id)

        return HStack(alignment: .top, spacing: 14) {
            // Checkbox button
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    if isDone {
                        completedExerciseIDs.remove(exercise.id)
                    } else {
                        completedExerciseIDs.insert(exercise.id)
                    }
                }
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isDone ? Color.statusSuccess : Color.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            // Step number pill
            Text("\(index)")
                .font(.caption2.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Color.brandPrimary.opacity(0.12), in: Circle())
                .foregroundStyle(.brandPrimary)
                .padding(.top, 2)

            // Exercise details
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(exercise.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(isDone)
                        .foregroundStyle(isDone ? Color.textSecondary : Color.textPrimary)

                    Spacer()

                    Text(exercise.duration)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.textTertiary)
                }

                HStack(spacing: 8) {
                    Label(exercise.targetMuscle, systemImage: "target")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.brandPrimary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.brandPrimary)

                    Label(exercise.repetitions, systemImage: "repeat")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.brandSecondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.brandSecondary)
                }

                Text(exercise.instructions)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            isDone
                ? Color.statusSuccess.opacity(0.05)
                : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDone ? Color.statusSuccess.opacity(0.2) : Color(nsColor: .separatorColor),
                    lineWidth: 1
                )
        )
    }

    // MARK: — Safety Notes Card

    private var safetyNotesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.statusWarning)
                Text("WORKPLACE SAFETY & COMFORT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.statusWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(routine.safetyNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusWarning.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.statusWarning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: — Guardrail Disclaimer

    private var disclaimerFooter: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.caption2)
                .foregroundStyle(.textTertiary)
            Text(routine.disclaimer)
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: — Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: 14) {
            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                onComplete?()
                dismiss()
            } label: {
                Label("Complete Recovery Routine", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.statusSuccess)
            .controlSize(.large)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
                    instructions: "Sit upright, look straight ahead, gently pull head backward.",
                    repetitions: "5 reps • 5-second hold",
                    targetMuscle: "Deep Neck Flexors",
                    duration: "45s"
                )
            ],
            totalDuration: "2 minutes",
            safetyNotes: ["Perform all movements in a comfortable, pain-free range."]
        )
    )
}
