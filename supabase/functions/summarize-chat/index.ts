// index.ts
//
// Edge function: summarize-chat
//
// Summarizes a chat conversation into a journal entry using Gemini.
// Takes the conversation messages and generates a title + content
// that captures the key insights and reflections.
//
// Deploy: supabase functions deploy summarize-chat
//

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ============================================================
// CONFIGURATION
// ============================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const GEMINI_CHAT_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

const SYSTEM_PROMPT = `You are a journal summarization assistant for Memento, a personal journaling app.

Your task is to transform a conversation between a user and an AI assistant (about the user's journal entries, emotions, and reflections) into a thoughtful journal entry.

Guidelines:
- Write in FIRST PERSON as if the user is writing their own journal entry
- Focus on the user's insights, realizations, and emotional discoveries
- Capture the essence of the conversation without being too detailed
- Create a meaningful title that reflects the main theme (3-8 words)
- Write 2-4 paragraphs of reflective content
- Use a warm, introspective tone appropriate for personal journaling
- Do NOT include meta-commentary about the conversation itself
- Do NOT reference "the AI" or "our conversation" - write as pure self-reflection

Return valid JSON only:
{
  "title": "Brief meaningful title (3-8 words)",
  "content": "2-4 paragraph summary in first person, focusing on insights and reflections"
}`;

// JSON schema for structured responses
const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    content: { type: "string" }
  },
  required: ["title", "content"]
};

// ============================================================
// TYPES
// ============================================================

interface SummaryRequest {
  sessionId?: string;
  messages: Array<{
    role: string;
    content: string;
  }>;
}

// ============================================================
// MAIN HANDLER
// ============================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ============================================================
    // 1. AUTHENTICATE
    // ============================================================

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header', code: 'AUTH_REQUIRED' }, 401);
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      console.error('Auth error:', userError);
      return jsonResponse({ error: 'Unauthorized', code: 'AUTH_FAILED' }, 401);
    }

    // ============================================================
    // 2. PARSE REQUEST
    // ============================================================

    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    let body: SummaryRequest;
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Invalid JSON body' }, 400);
    }

    if (!body.messages || body.messages.length === 0) {
      return jsonResponse({ error: 'Messages are required' }, 400);
    }

    console.log(`📝 Summarize request from user ${user.id.substring(0, 8)}... (${body.messages.length} messages)`);

    // ============================================================
    // 3. BUILD CONVERSATION TEXT
    // ============================================================

    const conversationText = body.messages
      .map(m => {
        const role = m.role === 'user' ? 'User' : 'Assistant';
        // Clean up assistant messages - extract body if JSON
        let content = m.content;
        if (m.role === 'assistant') {
          try {
            const parsed = JSON.parse(content);
            if (parsed.body) {
              content = parsed.body;
            }
          } catch {
            // Not JSON, use as-is
          }
        }
        return `${role}: ${content}`;
      })
      .join('\n\n');

    // ============================================================
    // 4. CALL GEMINI
    // ============================================================

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY not configured');
    }

    const geminiResponse = await fetch(`${GEMINI_CHAT_URL}?key=${geminiApiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{
          role: 'user',
          parts: [{ text: `Here is the conversation to summarize:\n\n${conversationText}` }]
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1000,
          responseMimeType: 'application/json',
          responseSchema: RESPONSE_SCHEMA,
        },
      }),
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error(`Gemini API error: ${geminiResponse.status}`, errorText.substring(0, 500));
      throw new Error(`Gemini API error: ${geminiResponse.status}`);
    }

    const geminiData = await geminiResponse.json();

    // Log usage metadata if present
    if (geminiData.usageMetadata) {
      console.log('Gemini usage_metadata:', JSON.stringify(geminiData.usageMetadata));
    }

    // Extract response text
    const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) {
      throw new Error('Empty response from Gemini');
    }

    console.log('Gemini raw response:', rawText.substring(0, 200));

    // ============================================================
    // 5. PARSE AND RETURN
    // ============================================================

    let summary: { title: string; content: string };
    try {
      summary = JSON.parse(rawText);
    } catch {
      console.error('Failed to parse Gemini response as JSON:', rawText.substring(0, 300));
      // Fallback: create a simple summary
      summary = {
        title: "Reflection from Today",
        content: rawText
      };
    }

    // Validate response structure
    if (!summary.title || !summary.content) {
      console.error('Invalid summary structure:', summary);
      throw new Error('Invalid summary structure from Gemini');
    }

    console.log(`✅ Summary generated: "${summary.title.substring(0, 30)}..."`);

    return jsonResponse({
      title: summary.title,
      content: summary.content
    }, 200);

  } catch (error) {
    console.error('Summarize function error:', error);
    return jsonResponse({
      error: 'Failed to generate summary',
      message: error instanceof Error ? error.message : 'Unknown error'
    }, 500);
  }
});

// ============================================================
// HELPERS
// ============================================================

function jsonResponse(data: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
