//
//  Entry.swift
//  MeetMemento
//
//  Lightweight UI-facing journal entry model.
//  For API/database operations, use JournalEntry (Codable model with full schema).
//
//  Entry vs JournalEntry:
//  - Entry: UI display model with minimal properties (title, text, dates)
//  - JournalEntry: Full Codable model for Supabase with userId, wordCount, sentiment, etc.
//
//  The EntryViewModel handles mapping between these models.
//

import Foundation

/// Lightweight journal entry model for UI rendering.
/// This model is used throughout the UI layer for displaying entries.
/// For API operations, convert to/from JournalEntry via EntryViewModel.
public struct Entry: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String = "", text: String = "", createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

// MARK: - UI Helpers

extension Entry {
    public var displayTitle: String {
        title.isEmpty ? "Untitled Entry" : title
    }

    public var excerpt: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "No text" }
        return String(trimmed.prefix(100))
    }
}

// MARK: - Sample Data for Previews

extension Entry {
    public static let sampleEntries: [Entry] = [
        Entry(title: "Morning Thoughts", text: "Today was a productive day..."),
        Entry(title: "Evening Reflection", text: "I learned something new today...")
    ]
}

// MARK: - Type Alias

/// Type alias for clarity - UIEntry is the lightweight UI model
public typealias UIEntry = Entry
