//
//  EntryViewModel.swift
//  MeetMemento
//
//  Minimal stub for managing journal entries (UI boilerplate).
//

import Foundation
import SwiftUI

@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Month Grouping (for UI display)

    var entriesByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.createdAt)?.start ?? entry.createdAt
        }
        return grouped.map { (monthStart, entries) in
            MonthGroup(monthStart: monthStart, entries: entries.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.monthStart > $1.monthStart }
    }

    // MARK: - CRUD Operations (in-memory only)

    func loadEntriesIfNeeded() async {
        // Stub: No-op
    }

    func loadEntries() async {
        isLoading = true
        // Stub: Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }

    func refreshEntries() async {
        await loadEntries()
    }

    func createEntry(title: String, text: String) {
        let newEntry = Entry(title: title.isEmpty ? "Untitled" : title, text: text)
        entries.insert(newEntry, at: 0)
    }

    func updateEntry(_ entry: Entry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        }
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
    }

    func loadMockEntries() {
        entries = Entry.sampleEntries
    }
}

// MARK: - Month Group Model

struct MonthGroup: Identifiable {
    let id = UUID()
    let monthStart: Date
    let entries: [Entry]

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthStart)
    }

    var entryCount: Int { entries.count }
}
