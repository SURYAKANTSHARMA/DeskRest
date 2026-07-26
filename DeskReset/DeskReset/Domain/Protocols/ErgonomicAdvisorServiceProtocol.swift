//
//  ErgonomicAdvisorServiceProtocol.swift
//  DeskReset
//
//  Protocol contract for generating structured ergonomic recovery routines.
//

import Foundation

protocol ErgonomicAdvisorServiceProtocol: AnyObject {
    /// Generates a strongly-typed ErgonomicRecoveryRoutine for a detected posture assessment.
    /// Strictly generates ergonomic workplace advice — NEVER medical advice.
    func generateRoutine(for assessment: PostureAssessment) async -> ErgonomicRecoveryRoutine
}
