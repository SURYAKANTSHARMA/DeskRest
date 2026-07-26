//
//  ErgonomicAdvisorService.swift
//  DeskReset
//
//  Structured Ergonomic Recovery Routine Generation Engine.
//  Generates strongly typed ErgonomicRecoveryRoutine models strictly enforcing
//  workplace ergonomic advice guardrails — NEVER medical advice.
//

import Foundation
import OSLog

final class ErgonomicAdvisorService: ErgonomicAdvisorServiceProtocol {

    init() {}

    // MARK: - Generate Structured Routine

    func generateRoutine(for assessment: PostureAssessment) async -> ErgonomicRecoveryRoutine {
        Logger.services.info("Generating structured ergonomic recovery routine for assessment score=\(assessment.score)")

        // Identify primary issue from assessment
        if let primaryIssue = assessment.issues.first {
            return routineForIssue(primaryIssue.type)
        }

        // Default healthy posture maintenance routine
        return healthyMaintenanceRoutine()
    }

    // MARK: — Issue-Specific Structured Routine Generators

    private func routineForIssue(_ issueType: PostureIssue.IssueType) -> ErgonomicRecoveryRoutine {
        switch issueType {
        case .forwardHead:
            return ErgonomicRecoveryRoutine(
                timestamp: Date(),
                detectedIssue: "Forward Head Posture",
                explanation: "Sustained forward head positioning increases effective head weight on neck flexors and upper back muscles, causing desk fatigue.",
                exercises: [
                    ErgonomicExercise(
                        title: "Chin Retraction & Tuck",
                        instructions: "Sit upright, look straight ahead, and gently pull your head backwards as if creating a double chin. Hold briefly, then release.",
                        repetitions: "5 reps • 5-second hold",
                        targetMuscle: "Deep Neck Flexors",
                        duration: "45s"
                    ),
                    ErgonomicExercise(
                        title: "Chest & Collarbone Opener",
                        instructions: "Interlace fingers behind your back or place hands on lower back. Gently roll shoulders back and lift chest upward.",
                        repetitions: "3 reps • 10-second hold",
                        targetMuscle: "Pectoralis Major & Minor",
                        duration: "40s"
                    ),
                    ErgonomicExercise(
                        title: "Seated Neck Lengthener",
                        instructions: "Drop your left ear gently toward left shoulder until you feel a comfortable stretch along right neck side. Repeat on right.",
                        repetitions: "2 reps per side • 10-second hold",
                        targetMuscle: "Upper Trapezius",
                        duration: "35s"
                    )
                ],
                totalDuration: "2 minutes",
                safetyNotes: [
                    "Perform all movements in a comfortable, pain-free range.",
                    "Do not force or jerk the head backward.",
                    "If you experience dizziness or sharp pain, stop immediately."
                ]
            )

        case .roundedShoulders:
            return ErgonomicRecoveryRoutine(
                timestamp: Date(),
                detectedIssue: "Rounded Shoulders",
                explanation: "Prolonged typing and mouse use can cause internal shoulder rotation, shortening chest muscles and overstretching upper back stabilizers.",
                exercises: [
                    ErgonomicExercise(
                        title: "Scapular Squeeze & Retraction",
                        instructions: "Sit tall with arms at sides bent at 90 degrees. Squeeze shoulder blades back and together as if pinching a pencil.",
                        repetitions: "8 reps • 4-second hold",
                        targetMuscle: "Rhomboids & Mid Trapezius",
                        duration: "45s"
                    ),
                    ErgonomicExercise(
                        title: "Goalpost Shoulder Opener",
                        instructions: "Raise arms to 90 degrees in a goalpost shape. Draw elbows backward gently while keeping core stable.",
                        repetitions: "5 reps • 6-second hold",
                        targetMuscle: "Anterior Deltoids & Pectorals",
                        duration: "45s"
                    ),
                    ErgonomicExercise(
                        title: "Backward Shoulder Rolls",
                        instructions: "Roll shoulders slowly in smooth backward circles, focusing on opening the chest at the top of each rotation.",
                        repetitions: "10 backward rotations",
                        targetMuscle: "Shoulder Girdle",
                        duration: "30s"
                    )
                ],
                totalDuration: "2 minutes",
                safetyNotes: [
                    "Keep your neck relaxed throughout the movements.",
                    "Avoid arching your lower back while squeezing shoulder blades.",
                    "Discontinue if you feel shoulder pinching or discomfort."
                ]
            )

        case .shoulderImbalance:
            return ErgonomicRecoveryRoutine(
                timestamp: Date(),
                detectedIssue: "Shoulder Height Imbalance",
                explanation: "Habitual side-leaning or single-arm mouse bias creates uneven shoulder height, straining one side of your neck and upper back.",
                exercises: [
                    ErgonomicExercise(
                        title: "Elevated Shoulder Release",
                        instructions: "Inhale and shrug elevated shoulder up toward ear, hold 3 seconds, then exhale and drop shoulder down completely.",
                        repetitions: "5 reps • 3-second hold",
                        targetMuscle: "Levator Scapulae",
                        duration: "40s"
                    ),
                    ErgonomicExercise(
                        title: "Side Neck Stretch",
                        instructions: "Anchor your right hand under seat edge. Tilt left ear to left shoulder until feeling a gentle neck stretch.",
                        repetitions: "3 reps • 10-second hold",
                        targetMuscle: "Upper Trapezius",
                        duration: "45s"
                    ),
                    ErgonomicExercise(
                        title: "Bilateral Arm Reach",
                        instructions: "Extend both arms straight overhead, reach evenly toward the ceiling, then lower arms back down to desk.",
                        repetitions: "4 reps • 5-second hold",
                        targetMuscle: "Latissimus & Upper Back",
                        duration: "35s"
                    )
                ],
                totalDuration: "2 minutes",
                safetyNotes: [
                    "Check that weight is evenly distributed across both seat bones.",
                    "Ensure mouse and keyboard are centered within easy reach.",
                    "Keep movement gradual and controlled."
                ]
            )

        case .torsoLean:
            return ErgonomicRecoveryRoutine(
                timestamp: Date(),
                detectedIssue: "Torso Lateral Lean",
                explanation: "Leaning laterally to one side unevenly loads spinal discs and core stabilizing muscles, leading to lower back fatigue.",
                exercises: [
                    ErgonomicExercise(
                        title: "Seated Side Bend Stretch",
                        instructions: "Place right hand on seat. Raise left arm overhead and lean gently to the right until feeling a side torso stretch.",
                        repetitions: "3 reps per side • 8-second hold",
                        targetMuscle: "Quadratus Lumborum & Obliques",
                        duration: "50s"
                    ),
                    ErgonomicExercise(
                        title: "Seated Spine Alignment Reset",
                        instructions: "Press feet firmly into floor. Inhale, lengthen spine upward, roll shoulders back, and place hands flat on thighs.",
                        repetitions: "4 deep breath cycles",
                        targetMuscle: "Spinal Erectors",
                        duration: "40s"
                    ),
                    ErgonomicExercise(
                        title: "Seated Gentle Torso Twist",
                        instructions: "Place right hand on left knee. Inhale tall, then exhale and turn torso gently to the left. Repeat on right.",
                        repetitions: "2 reps per side • 8-second hold",
                        targetMuscle: "Thoracic Rotators",
                        duration: "30s"
                    )
                ],
                totalDuration: "2 minutes",
                safetyNotes: [
                    "Keep both feet flat on the floor during stretches.",
                    "Twist gently from mid-back without forcing lower back.",
                    "Discontinue if you feel sharp spinal pain."
                ]
            )
        }
    }

    private func healthyMaintenanceRoutine() -> ErgonomicRecoveryRoutine {
        ErgonomicRecoveryRoutine(
            timestamp: Date(),
            detectedIssue: "Posture Maintenance",
            explanation: "Your posture alignment is currently great! Take a brief 90-second mobility micro-break to maintain circulation and eye comfort.",
            exercises: [
                ErgonomicExercise(
                    title: "20-20-20 Eye & Neck Rest",
                    instructions: "Look away from screen at an object 20 feet away. Slowly turn head left then right.",
                    repetitions: "20 seconds",
                    targetMuscle: "Ocular & Neck Muscles",
                    duration: "30s"
                ),
                ErgonomicExercise(
                    title: "Seated Overhead Extension",
                    instructions: "Interlace fingers, reach palms up toward ceiling, and take 2 deep abdominal breaths.",
                    repetitions: "2 deep breaths",
                    targetMuscle: "Full Upper Body",
                    duration: "30s"
                ),
                ErgonomicExercise(
                    title: "Wrist & Finger Release",
                    instructions: "Extend arms forward, flex wrists up and down, and gently open and close hands.",
                    repetitions: "5 flexions",
                    targetMuscle: "Forearm Flexors",
                    duration: "30s"
                )
            ],
            totalDuration: "90 seconds",
            safetyNotes: [
                "Keep movements relaxed and natural."
            ]
        )
    }
}
