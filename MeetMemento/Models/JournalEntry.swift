//
//  JournalEntry.swift
//  MeetMemento
//
//  Full Codable journal entry model for Supabase API operations.
//  For UI display, use Entry (lightweight model with minimal properties).
//
//  JournalEntry vs Entry:
//  - JournalEntry: Codable model matching Supabase schema (userId, wordCount, sentiment, etc.)
//  - Entry: Lightweight UI model with just title, text, and dates
//
//  The EntryViewModel handles mapping between these models.
//

import Foundation

/// Full journal entry model for API/database operations.
/// Maps to the `journal_entries` Supabase table with all schema fields.
/// For UI rendering, convert to Entry via EntryViewModel.
public struct JournalEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public var title: String
    public var content: String
    public var wordCount: Int?
    public var sentimentScore: Double? // numeric
    public var isDeleted: Bool
    public var deletedAt: Date?
    public var contentHash: String?
    public let createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case wordCount = "word_count"
        case sentimentScore = "sentiment_score"
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
        case contentHash = "content_hash"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String,
        wordCount: Int? = nil,
        sentimentScore: Double? = nil,
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        contentHash: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.wordCount = wordCount
        self.sentimentScore = sentimentScore
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mocks
extension JournalEntry {
    public static let mock = JournalEntry(
        userId: UUID(),
        title: "A Day to Remember",
        content: "Today was absolutely wonderful. I felt so productive and calm.",
        wordCount: 12,
        sentimentScore: 0.85,
        isDeleted: false
    )
}

// MARK: - Type Alias

/// Type alias for clarity - APIEntry is the full Codable model for Supabase
public typealias APIEntry = JournalEntry
