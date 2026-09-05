//
//  DeskResetTests.swift
//  DeskResetTests
//
//  Created by Suryakant Sharma on 25/07/26.
//

import Testing
import Foundation
@testable import DeskReset

@Suite(.serialized)
struct DeskResetTests {

    private func makeTestService() -> (AppRatingService, UserDefaults) {
        let suiteName = "test_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let service = AppRatingService(userDefaults: defaults)
        return (service, defaults)
    }

    @Test func testAppRatingInitialStateNotEligible() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        #expect(!service.hasRated)
        #expect(service.routinesCompletedCount == 0)
        #expect(service.sessionsCompletedCount == 0)
        #expect(!service.shouldPromptForRating())
    }

    @Test func testAppRatingEligibilityAfterRoutines() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        // 1 routine is not enough (minimum 2)
        service.recordRoutineCompleted()
        #expect(service.routinesCompletedCount == 1)
        #expect(!service.shouldPromptForRating())

        // 2 routines reaches threshold
        service.recordRoutineCompleted()
        #expect(service.routinesCompletedCount == 2)
        #expect(service.shouldPromptForRating())
    }

    @Test func testAppRatingEligibilityAfterSessions() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        // Complete 3 sessions
        service.recordSessionCompleted()
        service.recordSessionCompleted()
        #expect(!service.shouldPromptForRating())

        service.recordSessionCompleted()
        #expect(service.sessionsCompletedCount == 3)
        #expect(service.shouldPromptForRating())
    }

    @Test func testPromptShownPreventsDuplicatePromptOnSameVersion() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        service.forceEligibleForTesting()
        #expect(service.shouldPromptForRating())

        service.recordPromptShown(trigger: "test")
        #expect(!service.shouldPromptForRating())
    }

    @Test func testHasRatedPermanentlySuppressesPrompt() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        service.forceEligibleForTesting()
        #expect(service.shouldPromptForRating())

        service.hasRated = true
        #expect(!service.shouldPromptForRating())
    }

    @Test func testDismissPromptCooldown() async throws {
        let (service, defaults) = makeTestService()
        defer { defaults.removePersistentDomain(forName: defaults.description) }

        service.forceEligibleForTesting()

        // Dismiss with remindLater = true
        service.dismissPrompt(remindLater: true, action: "test_maybe_later")
        #expect(service.declinedDate != nil)
        #expect(!service.shouldPromptForRating())
    }
}
