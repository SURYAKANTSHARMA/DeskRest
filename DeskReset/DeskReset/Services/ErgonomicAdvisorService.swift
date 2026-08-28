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

    // MARK: - Generate AI Coach Guidance (Data-Driven)

    func generateGuidance(
        todayLogs: [PostureLog],
        allLogs: [PostureLog],
        currentAssessment: PostureAssessment?,
        isMonitoring: Bool,
        isCalibrated: Bool
    ) -> AICoachGuidance {
        let calendar = Calendar.current
        let validTodayLogs = todayLogs.filter { $0.issuesSummary != "Away" }
        let validAllLogs = allLogs.filter { $0.issuesSummary != "Away" }
        let todayCount = validTodayLogs.count
        let historicalCount = validAllLogs.count

        // 1. Check calibration & idle states
        if !isCalibrated {
            let routine = healthyMaintenanceRoutine()
            return AICoachGuidance(
                type: .setupGuide,
                headline: "Calibrate Your Baseline",
                badgeText: "Setup Required",
                badgeIcon: "figure.stand",
                dataMetricText: "No baseline recorded",
                diagnosticExplanation: "DeskReset needs a 10-second calibration to establish your unique seated posture baseline for millimeter-accurate tracking.",
                ergonomicFixTitle: "🖥️ Neutral Eye-Level Alignment",
                ergonomicFixDetails: "Sit comfortably upright, relax your shoulders, and position your display so the top 1/3 of the bezel meets your natural horizontal gaze.",
                targetArea: "Full Spine & Neck",
                microExerciseTitle: "Posture Alignment Check",
                microExerciseDuration: "30s • 1 rep",
                microExerciseTarget: "Spinal Erectors",
                microExerciseInstruction: "Lengthen spine upward, roll shoulders back and down, and take 2 deep centering breaths before starting calibration.",
                habitTip: "Recalibrate whenever you change chairs or switch between standing and sitting desk setups.",
                routine: routine
            )
        }

        if todayCount == 0 && !isMonitoring {
            let routine = healthyMaintenanceRoutine()
            let daysActive = Set(validAllLogs.map { calendar.startOfDay(for: $0.timestamp) }).count
            let metricStr = historicalCount > 0 ? "Based on \(historicalCount) historical scans across \(daysActive) days" : "Ready to monitor"
            return AICoachGuidance(
                type: .setupGuide,
                headline: "Personalized Posture Coach",
                badgeText: "System Ready",
                badgeIcon: "sparkles",
                dataMetricText: metricStr,
                diagnosticExplanation: historicalCount > 0
                    ? "Welcome back! Start monitoring to resume real-time angle tracking and receive tailored ergonomic interventions."
                    : "DeskReset tracks cervical spine tilt, shoulder symmetry, and upper back curvature to prevent repetitive strain injuries.",
                ergonomicFixTitle: "🖥️ 90-90-90 Workstation Check",
                ergonomicFixDetails: "Position screen 20–28 inches away at eye level. Adjust chair height so elbows and knees form comfortable 90° angles with feet flat on the floor.",
                targetArea: "Workstation Ergonomics",
                microExerciseTitle: "20-20-20 Vision & Neck Reset",
                microExerciseDuration: "30s",
                microExerciseTarget: "Ocular & Cervical",
                microExerciseInstruction: "Look at an object 20 feet away for 20 seconds, then slowly roll shoulders backward 5 times.",
                habitTip: "Start monitoring at the beginning of each focus block to capture fatigue trends before discomfort sets in.",
                routine: routine
            )
        }

        // 2. Count issue frequencies today
        var headCount = 0
        var shoulderCount = 0
        var backCount = 0
        var torsoCount = 0

        for log in validTodayLogs {
            let summary = log.issuesSummary ?? ""
            if summary.contains("Forward Head") { headCount += 1 }
            if summary.contains("Uneven Shoulders") || summary.contains("Shoulder Imbalance") { shoulderCount += 1 }
            if summary.contains("Rounded Shoulders") { backCount += 1 }
            if summary.contains("Torso Lean") { torsoCount += 1 }
        }

        // Also check historical totals across past days
        var histHeadCount = 0
        var histShoulderCount = 0
        var histBackCount = 0
        var histTorsoCount = 0
        for log in validAllLogs {
            let summary = log.issuesSummary ?? ""
            if summary.contains("Forward Head") { histHeadCount += 1 }
            if summary.contains("Uneven Shoulders") || summary.contains("Shoulder Imbalance") { histShoulderCount += 1 }
            if summary.contains("Rounded Shoulders") { histBackCount += 1 }
            if summary.contains("Torso Lean") { histTorsoCount += 1 }
        }

        // 3. Time-of-day fatigue slump detection
        let morningLogs = validTodayLogs.filter { calendar.component(.hour, from: $0.timestamp) < 12 }
        let afternoonLogs = validTodayLogs.filter {
            let h = calendar.component(.hour, from: $0.timestamp)
            return h >= 12 && h < 17
        }
        let eveningLogs = validTodayLogs.filter { calendar.component(.hour, from: $0.timestamp) >= 17 }

        let morningAvg = morningLogs.isEmpty ? 0 : morningLogs.reduce(0) { $0 + $1.score } / morningLogs.count
        let afternoonAvg = afternoonLogs.isEmpty ? 0 : afternoonLogs.reduce(0) { $0 + $1.score } / afternoonLogs.count
        let isAfternoonSlump = morningLogs.count >= 3 && afternoonLogs.count >= 3 && (morningAvg - afternoonAvg >= 6)

        // 4. Identify primary struggle
        let struggles: [(PostureIssue.IssueType, Int, Int)] = [
            (.forwardHead, headCount, histHeadCount),
            (.roundedShoulders, backCount, histBackCount),
            (.shoulderImbalance, shoulderCount, histShoulderCount),
            (.torsoLean, torsoCount, histTorsoCount)
        ]
        let sortedStruggles = struggles.sorted { $0.1 > $1.1 }
        let topStruggle = sortedStruggles.first

        let todayAvg = validTodayLogs.isEmpty ? 0 : validTodayLogs.reduce(0) { $0 + $1.score } / validTodayLogs.count

        // 5. Synthesize guidance based on top issue
        if let worst = topStruggle, worst.1 > 0 {
            let issueType = worst.0
            let countToday = worst.1
            let percentToday = Int(Double(countToday) / Double(max(1, todayCount)) * 100)
            let routine = routineForIssue(issueType)

            switch issueType {
            case .forwardHead:
                let headline = isAfternoonSlump ? "Afternoon Neck Fatigue Detected" : "Forward Head Drift Detected"
                let badge = isAfternoonSlump ? "⚡️ Slump Pattern" : "Flagged in \(percentToday)% of Scans"
                let metric = "Detected in \(countToday) of \(todayCount) checks today"
                let diagnostic = "Your head drifted forward in \(percentToday)% of today's checks (\(worst.2) total historically). Sustained forward tilt places up to 30 lbs of extra gravitational load on your cervical spine."
                let fixTitle = "🖥️ Monitor Elevation & Distance"
                let fixDetails = "Raise your monitor 2–3 inches so the top 1/3 of the display is at eye level, roughly 20–28 inches away. This prevents unconscious cranio-cervical extension."
                let microTitle = "Chin Retraction & Tuck"
                let microDuration = "45s • 5 reps"
                let microTarget = "Deep Neck Flexors"
                let microInstruction = "Sit tall, pull chin straight back as if making a double chin. Hold 5s, release. Opens upper cervical joints."
                let habit = isAfternoonSlump
                    ? "Your score drops by \(morningAvg - afternoonAvg) pts after 1 PM. Stand up for 60 seconds every 45 minutes to refresh blood flow."
                    : "Increase text zoom to 110%–125% to eliminate the instinctive urge to lean in toward small screen text."

                return AICoachGuidance(
                    type: isAfternoonSlump ? .fatiguePattern : .correction,
                    headline: headline,
                    badgeText: badge,
                    badgeIcon: isAfternoonSlump ? "bolt.fill" : "exclamationmark.triangle.fill",
                    dataMetricText: metric,
                    diagnosticExplanation: diagnostic,
                    ergonomicFixTitle: fixTitle,
                    ergonomicFixDetails: fixDetails,
                    targetArea: "Cervical Spine (Neck)",
                    microExerciseTitle: microTitle,
                    microExerciseDuration: microDuration,
                    microExerciseTarget: microTarget,
                    microExerciseInstruction: microInstruction,
                    habitTip: habit,
                    routine: routine
                )

            case .roundedShoulders:
                let headline = isAfternoonSlump ? "Upper Back Fatigue Slump" : "Shoulder Protraction Detected"
                let badge = isAfternoonSlump ? "⚡️ Slump Pattern" : "Flagged in \(percentToday)% of Scans"
                let metric = "Detected in \(countToday) of \(todayCount) checks today"
                let diagnostic = "Shoulders were rolled forward in \(percentToday)% of scans. Prolonged forward reaching tightens the pectorals while overstretching rhomboids and middle trapezius."
                let fixTitle = "⌨️ Keyboard & Mouse Proximity"
                let fixDetails = "Pull keyboard and mouse 3–4 inches closer to torso so elbows rest comfortably at 90° by your ribcage without reaching forward."
                let microTitle = "Scapular Pinch & Goalpost Stretch"
                let microDuration = "45s • 8 reps"
                let microTarget = "Rhomboids & Mid Traps"
                let microInstruction = "Bring elbows to sides at 90°, squeeze shoulder blades backward together firmly for 4 seconds, then relax."
                let habit = "Avoid anchoring elbows forward on desk edges, which collapses your shoulder girdle into internal rotation."

                return AICoachGuidance(
                    type: isAfternoonSlump ? .fatiguePattern : .correction,
                    headline: headline,
                    badgeText: badge,
                    badgeIcon: isAfternoonSlump ? "bolt.fill" : "exclamationmark.triangle.fill",
                    dataMetricText: metric,
                    diagnosticExplanation: diagnostic,
                    ergonomicFixTitle: fixTitle,
                    ergonomicFixDetails: fixDetails,
                    targetArea: "Thoracic Spine & Shoulders",
                    microExerciseTitle: microTitle,
                    microExerciseDuration: microDuration,
                    microExerciseTarget: microTarget,
                    microExerciseInstruction: microInstruction,
                    habitTip: habit,
                    routine: routine
                )

            case .shoulderImbalance:
                let headline = "Uneven Shoulder Tilt Detected"
                let badge = "Flagged in \(percentToday)% of Scans"
                let metric = "Detected in \(countToday) of \(todayCount) checks today"
                let diagnostic = "Uneven shoulder height was recorded in \(percentToday)% of checks. Habitual side-leaning or single-arm mouse bias strains one side of your neck and trapezius."
                let fixTitle = "💺 Armrest & Chair Symmetry"
                let fixDetails = "Level both chair armrests to identical height. Ensure your mouse and keyboard are centered so you don't list toward your dominant hand."
                let microTitle = "Elevated Shoulder Shrug & Release"
                let microDuration = "40s • 5 reps"
                let microTarget = "Levator Scapulae"
                let microInstruction = "Inhale, shrug the higher shoulder upward for 3 seconds, then exhale and drop both shoulders completely down."
                let habit = "Check that your weight is distributed 50/50 across both sit bones rather than leaning onto one armrest."

                return AICoachGuidance(
                    type: .correction,
                    headline: headline,
                    badgeText: badge,
                    badgeIcon: "arrow.up.and.down",
                    dataMetricText: metric,
                    diagnosticExplanation: diagnostic,
                    ergonomicFixTitle: fixTitle,
                    ergonomicFixDetails: fixDetails,
                    targetArea: "Shoulder Girdle Symmetry",
                    microExerciseTitle: microTitle,
                    microExerciseDuration: microDuration,
                    microExerciseTarget: microTarget,
                    microExerciseInstruction: microInstruction,
                    habitTip: habit,
                    routine: routine
                )

            case .torsoLean:
                let headline = "Lateral Torso Lean Detected"
                let badge = "Flagged in \(percentToday)% of Scans"
                let metric = "Detected in \(countToday) of \(todayCount) checks today"
                let diagnostic = "Lateral spine tilt was detected in \(percentToday)% of checks. Off-center leaning unevenly compresses spinal discs and strains lower back stabilizers."
                let fixTitle = "🦶 Pelvic & Foot Foundation"
                let fixDetails = "Plant both feet flat on the floor (or use a footrest). Slide your hips firmly against the lumbar support curve."
                let microTitle = "Seated Side Bend & Spine Reset"
                let microDuration = "50s • 3 reps/side"
                let microTarget = "Quadratus Lumborum"
                let microInstruction = "Reach one arm overhead, lean gently toward the opposite side for 8 seconds, then switch sides."
                let habit = "Avoid crossing legs or tucking one foot under your seat, which twists your pelvis and causes compensatory spine tilt."

                return AICoachGuidance(
                    type: .correction,
                    headline: headline,
                    badgeText: badge,
                    badgeIcon: "arrow.triangle.2.circlepath",
                    dataMetricText: metric,
                    diagnosticExplanation: diagnostic,
                    ergonomicFixTitle: fixTitle,
                    ergonomicFixDetails: fixDetails,
                    targetArea: "Lumbar & Core Alignment",
                    microExerciseTitle: microTitle,
                    microExerciseDuration: microDuration,
                    microExerciseTarget: microTarget,
                    microExerciseInstruction: microInstruction,
                    habitTip: habit,
                    routine: routine
                )
            }
        }

        // 6. Healthy / Optimal Alignment Case
        let routine = healthyMaintenanceRoutine()
        let isHighQuality = todayAvg >= 80
        let metric = "\(todayCount) scans today · Average score: \(todayAvg)/100"
        let headline = isHighQuality ? "Optimal Posture Maintained" : "Balanced Posture Alignment"
        let badge = isHighQuality ? "✨ Peak Alignment" : "Solid Consistency"
        let diagnostic = "Great alignment! You've maintained balanced spinal curvature across \(todayCount) scans today with zero major postural flags."
        let fixTitle = "🖥️ Maintain Current Ergonomics"
        let fixDetails = "Your workstation geometry is dialed in! Keep your 90° elbow and knee angles consistent throughout your work sessions."
        let microTitle = "20-20-20 Micro-Break & Neck Rest"
        let microDuration = "30s • 1 rep"
        let microTarget = "Full Upper Body & Eyes"
        let microInstruction = "Look 20 feet away for 20 seconds. Take 2 slow deep breaths with fingers interlaced overhead."
        let habit = "Take a 30-second standup micro-break every 45–60 minutes to maintain spinal disc hydration and circulation."

        return AICoachGuidance(
            type: .optimal,
            headline: headline,
            badgeText: badge,
            badgeIcon: "checkmark.seal.fill",
            dataMetricText: metric,
            diagnosticExplanation: diagnostic,
            ergonomicFixTitle: fixTitle,
            ergonomicFixDetails: fixDetails,
            targetArea: "Full Body Posture Health",
            microExerciseTitle: microTitle,
            microExerciseDuration: microDuration,
            microExerciseTarget: microTarget,
            microExerciseInstruction: microInstruction,
            habitTip: habit,
            routine: routine
        )
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
