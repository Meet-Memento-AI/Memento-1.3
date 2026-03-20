//
//  ChatService.swift
//  MeetMemento
//
//  Service for chat session and message persistence.
//  Supports in-memory cache with optional Supabase database backend.
//

import Foundation
import Supabase

/// Service for loading and persisting chat sessions and messages.
/// When database tables exist, sessions and messages are stored in Supabase.
/// Falls back to in-memory cache when database is not yet configured.
class ChatService {
    static let shared = ChatService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Sessions

    /// Fetches chat sessions for the current user from the database.
    /// Returns empty array if not authenticated or tables don't exist yet.
    func fetchSessions() async throws -> [ChatSession] {
        guard client.auth.currentUser != nil else { return [] }

        do {
            let rows: [ChatSessionRow] = try await client
                .from("chat_sessions")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            return rows.map { $0.toChatSession() }
        } catch {
            #if DEBUG
            print("📋 [ChatService] fetchSessions failed (table may not exist): \(error)")
            #endif
            return []
        }
    }

    /// Saves a new chat session to the database.
    func saveSession(_ session: ChatSession) async throws {
        guard let userId = client.auth.currentUser?.id else { return }

        let row = ChatSessionRow(
            id: session.id,
            user_id: userId,
            title: session.title,
            created_at: session.createdAt
        )

        try await client
            .from("chat_sessions")
            .insert(row)
            .execute()
    }

    // MARK: - Messages

    /// Fetches messages for a session from the database.
    /// Returns nil if not found or table doesn't exist.
    func fetchMessages(sessionId: UUID) async throws -> [ChatMessage]? {
        guard client.auth.currentUser != nil else { return nil }

        do {
            let rows: [ChatMessageRow] = try await client
                .from("chat_messages")
                .select()
                .eq("session_id", value: sessionId)
                .order("created_at", ascending: true)
                .execute()
                .value

            return rows.compactMap { $0.toChatMessage() }
        } catch {
            #if DEBUG
            print("📋 [ChatService] fetchMessages failed: \(error)")
            #endif
            return nil
        }
    }

    /// Saves messages for a session to the database.
    func saveMessages(_ messages: [ChatMessage], sessionId: UUID) async throws {
        guard client.auth.currentUser != nil, !messages.isEmpty else { return }

        let rows = messages.compactMap { msg -> ChatMessageRow? in
            ChatMessageRow.from(message: msg, sessionId: sessionId)
        }

        guard !rows.isEmpty else { return }

        try await client
            .from("chat_messages")
            .upsert(rows, onConflict: "id")
            .execute()
    }
}

// MARK: - Database Row Types

private struct ChatSessionRow: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let created_at: Date

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case title
        case created_at
    }

    func toChatSession() -> ChatSession {
        ChatSession(id: id, title: title, createdAt: created_at)
    }
}

private struct ChatMessageRow: Codable {
    let id: UUID
    let session_id: UUID
    let content: String
    let is_from_user: Bool
    let created_at: Date
    let ai_heading1: String?
    let ai_heading2: String?
    let ai_body: String?
    let citations_json: String?

    enum CodingKeys: String, CodingKey {
        case id
        case session_id
        case content
        case is_from_user
        case created_at
        case ai_heading1
        case ai_heading2
        case ai_body
        case citations_json
    }

    static func from(message: ChatMessage, sessionId: UUID) -> ChatMessageRow? {
        let citationsJson: String?
        if let citations = message.citations, !citations.isEmpty,
           let data = try? JSONEncoder().encode(citations),
           let str = String(data: data, encoding: .utf8) {
            citationsJson = str
        } else {
            citationsJson = nil
        }

        let (h1, h2, body): (String?, String?, String?)
        if let ai = message.aiOutputContent {
            h1 = ai.heading1
            h2 = ai.heading2
            body = ai.body
        } else {
            h1 = nil
            h2 = nil
            body = message.content
        }

        return ChatMessageRow(
            id: message.id,
            session_id: sessionId,
            content: message.content,
            is_from_user: message.isFromUser,
            created_at: message.timestamp,
            ai_heading1: h1,
            ai_heading2: h2,
            ai_body: body,
            citations_json: citationsJson
        )
    }

    func toChatMessage() -> ChatMessage? {
        let citations: [JournalCitation]?
        if let json = citations_json,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([JournalCitation].self, from: data) {
            citations = decoded
        } else {
            citations = nil
        }

        if is_from_user {
            return ChatMessage(
                id: id,
                content: content,
                isFromUser: true,
                timestamp: created_at,
                citations: nil,
                aiOutputContent: nil,
                shouldAnimateOutput: false
            )
        }

        let bodyText = ai_body ?? content
        return ChatMessage.aiMessage(
            id: id,
            heading1: ai_heading1,
            heading2: ai_heading2,
            body: bodyText,
            citations: citations,
            timestamp: created_at,
            shouldAnimateOutput: false
        )
    }
}
