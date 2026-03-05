//
//  ChatHistoryList.swift
//  MeetMemento
//
//  Scrollable list of chat history items
//

import SwiftUI

public struct ChatHistoryList: View {
    let sessions: [ChatSession]
    let onSessionSelect: (ChatSession) -> Void

    @Environment(\.theme) private var theme

    public init(
        sessions: [ChatSession],
        onSessionSelect: @escaping (ChatSession) -> Void
    ) {
        self.sessions = sessions
        self.onSessionSelect = onSessionSelect
    }

    public var body: some View {
        if sessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sessions) { session in
                        ChatHistoryItem(session: session) {
                            onSessionSelect(session)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(theme.mutedForeground.opacity(0.5))

            Text("No chat history yet")
                .font(.headline)
                .foregroundStyle(theme.mutedForeground)

            Text("Start a conversation to see it here")
                .font(.subheadline)
                .foregroundStyle(theme.mutedForeground.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Chat History List") {
    ChatHistoryList(
        sessions: ChatSession.mockSessions,
        onSessionSelect: { session in
            print("Selected: \(session.title)")
        }
    )
    .useTheme()
    .useTypography()
}

#Preview("Empty State") {
    ChatHistoryList(
        sessions: [],
        onSessionSelect: { _ in }
    )
    .useTheme()
    .useTypography()
}
