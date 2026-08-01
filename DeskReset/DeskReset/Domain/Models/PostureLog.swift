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
    
    public init(timestamp: Date = .now, score: Int) {
        self.timestamp = timestamp
        self.score = score
    }
}
