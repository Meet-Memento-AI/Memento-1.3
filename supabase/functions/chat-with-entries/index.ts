// index.ts
//
// Edge function for AI chat with journal entries context
//
// Features:
// - Returns structured AIOutputContent (heading1, heading2, body, citations)
// - Robust JSON parsing to prevent raw JSON leaking to production
// - Higher max_tokens to prevent responses from being cut off early
// - JSON extraction fallback when model wraps output in markdown/text
//
// Deploy: supabase functions deploy chat-with-entries
//

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import OpenAI from 'https://deno.land/x/openai@v4.20.1/mod.ts';
import type {
  ChatRequest,
  ChatMessagePayload,
  JournalEntry,
  AIOutputContent,
  JournalCitation,
  OpenAIChatResponse,
  ErrorResponse
} from './types.ts';

// ============================================================
// CONFIGURATION
// ============================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const MAX_ENTRIES = 20;
const MAX_CONTENT_LENGTH = 400;
const MAX_TOKENS = 2500;  // Higher than generate-insights to prevent cut-off

// ============================================================
// MAIN HANDLER
// ============================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse(
        { error: 'Missing authorization header', code: 'AUTH_REQUIRED' },
        401
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return jsonResponse(
        { error: 'Unauthorized', code: 'AUTH_FAILED' },
        401
      );
    }

    if (req.method !== 'POST') {
      return jsonResponse(
        { error: 'Method not allowed', code: 'INVALID_METHOD' },
        405
      );
    }

    let body: ChatRequest;
    try {
      body = await req.json();
    } catch {
      return jsonResponse(
        { error: 'Invalid JSON body', code: 'INVALID_JSON' },
        400
      );
    }

    const { messages, entries } = body;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return jsonResponse(
        { error: 'Missing or invalid messages array', code: 'MISSING_MESSAGES' },
        400
      );
    }

    if (!entries || !Array.isArray(entries) || entries.length > MAX_ENTRIES) {
      return jsonResponse(
        { error: `Entries must be an array with 0-${MAX_ENTRIES} items`, code: 'INVALID_ENTRIES' },
        400
      );
    }

    const validEntries = entries.filter(
      (e: JournalEntry) => e?.content?.trim?.()?.length > 0
    );

    console.log(`💬 Chat request from user ${user.id.substring(0, 8)}... with ${messages.length} messages, ${validEntries.length} entries`);

    const content = await generateChatResponse(messages, validEntries);

    return jsonResponse(content, 200);
  } catch (error) {
    console.error('❌ chat-with-entries error:', error);
    return jsonResponse(
      {
        error: 'Failed to generate response. Please try again.',
        code: 'INTERNAL_ERROR'
      },
      500
    );
  }
});

// ============================================================
// OPENAI GENERATION
// ============================================================

async function generateChatResponse(
  messages: ChatMessagePayload[],
  entries: JournalEntry[]
): Promise<AIOutputContent> {
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY not configured');
  }

  const openai = new OpenAI({ apiKey });

  const entriesContext = entries.length > 0
    ? entries.map((e: JournalEntry) => ({
        date: formatDate(e.date),
        title: e.title || 'Untitled',
        content: e.content.substring(0, MAX_CONTENT_LENGTH)
      }))
    : [];

  const systemPrompt = `You are a warm journaling companion helping users explore their journal entries. Respond in a structured JSON format ONLY.

CRITICAL OUTPUT RULES:
1. Return ONLY a valid JSON object - no text, markdown, code blocks, or commentary before or after
2. Start with { and end with }
3. Use this exact structure:
{
  "heading1": "Optional main heading (2-6 words)",
  "heading2": "Optional subheading (or null)",
  "body": "Your main response in markdown (bold with **, italic with *). Reference specific journal content. Be conversational and supportive.",
  "citations": [{"entry_id": "uuid", "entry_title": "title", "entry_date": "YYYY-MM-DD", "excerpt": "relevant quote"}]
}

4. body is REQUIRED - write 2-4 paragraphs of thoughtful analysis
5. heading1 and heading2 are optional - use when they add clarity
6. citations: include 0-3 relevant entry references when you quote or reference specific entries. Use entry_id from context when available, or a placeholder UUID.
7. NEVER output raw JSON syntax as readable text - the response is parsed programmatically`;

  const userContent = `Conversation so far:
${messages.map((m: ChatMessagePayload) =>
  `${m.isFromUser === 'true' ? 'User' : 'Assistant'}: ${m.content}`
).join('\n\n')}

${entriesContext.length > 0 ? `Journal entries for context:\n${JSON.stringify(entriesContext)}` : 'No journal entries provided.'}

Respond with ONLY the JSON object (no other text).`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-4.1-nano-2025-04-14',
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userContent }
    ],
    temperature: 0.7,
    max_tokens: MAX_TOKENS,
    response_format: { type: 'json_object' }
  });

  const responseText = completion.choices[0]?.message?.content;
  if (!responseText?.trim()) {
    throw new Error('Empty response from AI');
  }

  const parsed = parseAndSanitizeResponse(responseText);
  return parsed;
}

/**
 * Parse AI response and NEVER return raw JSON to the client.
 * Handles: wrapped JSON, truncated JSON, markdown code blocks.
 */
function parseAndSanitizeResponse(responseText: string): AIOutputContent {
  let parsed: OpenAIChatResponse;

  try {
    parsed = JSON.parse(responseText);
  } catch {
    const extracted = extractJsonFromText(responseText);
    if (!extracted) {
      console.error('Failed to parse or extract JSON. First 300 chars:', responseText.substring(0, 300));
      throw new Error('AI returned invalid response format');
    }
    parsed = JSON.parse(extracted);
  }

  if (!parsed || typeof parsed !== 'object') {
    throw new Error('AI response was not a valid object');
  }

  const body = typeof parsed.body === 'string' ? parsed.body.trim() : '';
  if (!body) {
    throw new Error('AI response missing required body field');
  }

  const citations: JournalCitation[] = [];
  if (Array.isArray(parsed.citations)) {
    for (const c of parsed.citations) {
      if (c && typeof c.excerpt === 'string') {
        citations.push({
          id: typeof c.entry_id === 'string' ? c.entry_id : crypto.randomUUID(),
          entry_id: String(c.entry_id ?? ''),
          entry_title: String(c.entry_title ?? ''),
          entry_date: String(c.entry_date ?? ''),
          excerpt: String(c.excerpt).substring(0, 500)
        });
      }
    }
  }

  return {
    heading1: typeof parsed.heading1 === 'string' && parsed.heading1.trim()
      ? parsed.heading1.trim()
      : undefined,
    heading2: typeof parsed.heading2 === 'string' && parsed.heading2.trim()
      ? parsed.heading2.trim()
      : undefined,
    body,
    citations: citations.length > 0 ? citations : undefined
  };
}

/**
 * Extract JSON object from text that may contain markdown, prefixes, or suffixes.
 * Prevents raw "{body: ..." from ever reaching the client.
 */
function extractJsonFromText(text: string): string | null {
  const trimmed = text.trim();

  const codeBlockMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) {
    return codeBlockMatch[1].trim();
  }

  const firstBrace = trimmed.indexOf('{');
  const lastBrace = trimmed.lastIndexOf('}');

  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    return trimmed.substring(firstBrace, lastBrace + 1);
  }

  return null;
}

function formatDate(isoDate: string): string {
  try {
    return new Date(isoDate).toISOString().split('T')[0];
  } catch {
    return isoDate;
  }
}

function jsonResponse(data: AIOutputContent | ErrorResponse, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  });
}
