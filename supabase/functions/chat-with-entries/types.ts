// types.ts
//
// TypeScript type definitions for chat-with-entries edge function
// Matches Swift AIOutputContent and JournalCitation models
//

// ============================================================
// REQUEST TYPES (from Swift InsightsService)
// ============================================================

export interface JournalEntry {
  date: string;
  title: string;
  content: string;
  word_count: number;
}

export interface ChatMessagePayload {
  content: string;
  isFromUser: string;
}

export interface ChatRequest {
  messages: ChatMessagePayload[];
  entries: JournalEntry[];
}

// ============================================================
// RESPONSE TYPES (AIOutputContent for Swift)
// ============================================================

export interface JournalCitation {
  id?: string;
  entry_id: string;
  entry_title: string;
  entry_date: string;
  excerpt: string;
}

export interface AIOutputContent {
  heading1?: string;
  heading2?: string;
  body: string;
  citations?: JournalCitation[];
}

// ============================================================
// OPENAI RAW RESPONSE (model output schema)
// ============================================================

export interface OpenAIChatResponse {
  heading1?: string;
  heading2?: string;
  body: string;
  citations?: Array<{
    entry_id: string;
    entry_title: string;
    entry_date: string;
    excerpt: string;
  }>;
}

// ============================================================
// ERROR TYPES
// ============================================================

export interface ErrorResponse {
  error: string;
  code: string;
}
