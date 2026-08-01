//
//  PostureLog.swift
//  DeskReset
//
//  Persistent snapshot of the user's posture score at a specific time.
//

import Foundation
import SwiftData

@Model
public final class PostureLog {
    public var timestamp: Date
    public var score: Int
    public var issuesSummary: String?
    
    public init(timestamp: Date = .now, score: Int, issuesSummary: String? = nil) {
        self.timestamp = timestamp
        self.score = score
        self.issuesSummary = issuesSummary
    }
}
