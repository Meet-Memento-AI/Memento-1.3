//
//  ChatSession.swift
//  MeetMemento
//
//  Data model for chat session history
//

import Foundation

/// Represents a past chat session for history display
public struct ChatSession: Identifiable, Hashable {
    public let id: UUID
    /// The first message sent by the user (used as session title)
    public let title: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}

// MARK: - Mock Data

extension ChatSession {
    /// Mock sessions for UI development (titles are first user messages)
    static let mockSessions: [ChatSession] = [
        ChatSession(
            title: "What patterns do you see in my recent journal entries?",
            createdAt: Date().addingTimeInterval(-3600 * 2)
        ),
        ChatSession(
            title: "Help me understand my stress triggers from last week",
            createdAt: Date().addingTimeInterval(-86400)
        ),
        ChatSession(
            title: "Analyze my morning routine entries and their impact",
            createdAt: Date().addingTimeInterval(-86400 * 3)
        ),
        ChatSession(
            title: "What have I written about my friendships lately?",
            createdAt: Date().addingTimeInterval(-86400 * 7)
        ),
        ChatSession(
            title: "Summarize my mood patterns over the past month",
            createdAt: Date().addingTimeInterval(-86400 * 14)
        )
    ]
}
