// Pure helpers for chat Edge Function (unit-tested without Gemini / Supabase).

export interface MatchedEntry {
  id: string;
  content: string;
  created_at: string;
  similarity: number;
}

export interface ChatMessageRow {
  role: string;
  content: string;
}

export function buildContextBlock(entries: MatchedEntry[]): string {
  if (entries.length === 0) {
    return '[No journal entries matched this topic]';
  }

  const formatted = entries.map((e) => {
    const date = new Date(e.created_at);
    const label = date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
    return `[${label}] ${e.content}`;
  });

  return [
    '[Journal context — reference these naturally, do not quote them verbatim]',
    '',
    ...formatted,
    '',
    '[End of journal context]',
  ].join('\n');
}

export function buildGeminiContents(
  history: ChatMessageRow[],
  contextBlock: string,
  currentMessage: string,
): Array<{ role: string; parts: Array<{ text: string }> }> {
  const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

  for (const msg of history) {
    let content = msg.content;

    if (msg.role === 'assistant') {
      try {
        const parsed = JSON.parse(msg.content);
        if (parsed.body) {
          content = parsed.body;
        }
      } catch {
        // Not JSON (legacy message), use as-is
      }
    }

    contents.push({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: content }],
    });
  }

  contents.push({
    role: 'user',
    parts: [{ text: `${contextBlock}\n\n${currentMessage}` }],
  });

  return contents;
}

/** First text part from Gemini generateContent JSON response. */
export function extractGeminiResponseText(data: unknown): string {
  const d = data as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };
  const text = d.candidates?.[0]?.content?.parts?.[0]?.text;
  return typeof text === 'string' && text.length > 0
    ? text
    : "I'm having trouble connecting right now. Please try again in a moment.";
}

/**
 * Sanitizes response body to ensure users never see raw JSON.
 */
export function sanitizeResponseBody(text: string): string {
  const trimmed = text.trim();

  if (!trimmed.startsWith('{')) {
    return text;
  }

  const patterns = [
    /"body"\s*:\s*"((?:[^"\\]|\\.)*)"/,
    /"body"\s*:\s*'((?:[^'\\]|\\.)*)'/,
    /body:\s*["']([^"']+)["']/,
  ];

  for (const pattern of patterns) {
    const match = trimmed.match(pattern);
    if (match) {
      return match[1]
        .replace(/\\"/g, '"')
        .replace(/\\n/g, '\n')
        .replace(/\\t/g, '\t');
    }
  }

  console.warn('sanitizeResponseBody: Could not extract body from JSON-like text');
  return "I had trouble formulating a response. Could you try rephrasing your question?";
}

/**
 * Cleans parsed body by unwrapping nested JSON and sanitizing.
 */
export function cleanParsedBody(parsed: { body?: unknown }): string {
  if (typeof parsed.body !== 'string') {
    console.warn('cleanParsedBody: body is not a string:', typeof parsed.body);
    return "I had trouble formulating a response. Please try again.";
  }

  let bodyText: string = parsed.body;

  let attempts = 0;
  while (bodyText.trim().startsWith('{') && attempts < 3) {
    try {
      const nested = JSON.parse(bodyText);
      if (typeof nested.body === 'string' && nested.body.trim()) {
        bodyText = nested.body;
      } else {
        break;
      }
    } catch {
      break;
    }
    attempts++;
  }

  if (!bodyText.trim()) {
    return "I had trouble formulating a response. Please try again.";
  }

  if (bodyText.trim().startsWith('{')) {
    return sanitizeResponseBody(bodyText);
  }

  return bodyText;
}

/**
 * Extracts a usable body string from parsed response.
 */
export function extractBody(parsed: Record<string, unknown>): string | null {
  if (typeof parsed.body === 'string' && parsed.body.trim()) {
    return parsed.body.trim();
  }

  if (parsed.body && typeof parsed.body === 'object') {
    const bodyObj = parsed.body as Record<string, unknown>;
    if (typeof bodyObj.text === 'string' && bodyObj.text.trim()) {
      return bodyObj.text.trim();
    }
    if (typeof bodyObj.content === 'string' && bodyObj.content.trim()) {
      return bodyObj.content.trim();
    }
  }

  if (typeof parsed.response === 'string' && parsed.response.trim()) {
    return parsed.response.trim();
  }

  if (typeof parsed.text === 'string' && parsed.text.trim()) {
    return parsed.text.trim();
  }

  if (typeof parsed.message === 'string' && parsed.message.trim()) {
    return parsed.message.trim();
  }

  return null;
}
