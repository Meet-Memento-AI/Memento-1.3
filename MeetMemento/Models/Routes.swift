//
//  Routes.swift
//  MeetMemento
//
//  Navigation routes for the app
//

import Foundation

// MARK: - Navigation route for journal entry editor
public enum EntryRoute: Hashable {
    case create
    case createWithTitle(String)
    case createWithContent(title: String, content: String)
    case edit(Entry)
}

// MARK: - Navigation route for settings
public enum SettingsRoute: Hashable {
    case main
    case profile
    case appearance
    case about
}

// MARK: - Navigation route for AI Chat
public enum AIChatRoute: Hashable {
    case main
}

// MARK: - Navigation route for Monthly Insights
public enum MonthInsightRoute: Hashable {
    case detail(monthLabel: String, entryCount: Int)
}

// MARK: - Navigation route for Drawer Menu
public enum DrawerRoute: Hashable {
    case aboutYourself
    case journalGoals
}
