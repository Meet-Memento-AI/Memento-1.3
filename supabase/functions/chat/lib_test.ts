import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import {
  buildContextBlock,
  buildGeminiContents,
  cleanParsedBody,
  extractBody,
  extractGeminiResponseText,
  sanitizeResponseBody,
  type MatchedEntry,
} from './lib.ts';

Deno.test('buildContextBlock_empty_returnsPlaceholder', () => {
  assertEquals(buildContextBlock([]), '[No journal entries matched this topic]');
});

Deno.test('buildContextBlock_formatsEntries', () => {
  const entries: MatchedEntry[] = [
    {
      id: 'a',
      content: 'Hello journal',
      created_at: '2025-06-01T12:00:00.000Z',
      similarity: 0.9,
    },
  ];
  const block = buildContextBlock(entries);
  assertEquals(block.includes('[Journal context'), true);
  assertEquals(block.includes('Hello journal'), true);
  assertEquals(block.includes('[End of journal context]'), true);
});

Deno.test('buildGeminiContents_appendsUserMessageWithContext', () => {
  const history: { role: string; content: string }[] = [];
  const contents = buildGeminiContents(history, '[ctx]', 'Hi');
  assertEquals(contents.length, 1);
  assertEquals(contents[0].role, 'user');
  assertEquals(contents[0].parts[0].text.includes('[ctx]'), true);
  assertEquals(contents[0].parts[0].text.endsWith('Hi'), true);
});

Deno.test('buildGeminiContents_assistantJsonExtractsBody', () => {
  const history = [
    {
      role: 'assistant',
      content: JSON.stringify({ heading1: null, heading2: null, body: 'Only body' }),
    },
  ];
  const contents = buildGeminiContents(history, '[ctx]', 'Next');
  assertEquals(contents[0].role, 'model');
  assertEquals(contents[0].parts[0].text, 'Only body');
});

Deno.test('extractGeminiResponseText_readsCandidateText', () => {
  const text = extractGeminiResponseText({
    candidates: [{ content: { parts: [{ text: '{"body":"x"}' }] } }],
  });
  assertEquals(text, '{"body":"x"}');
});

Deno.test('extractGeminiResponseText_missingFallback', () => {
  const text = extractGeminiResponseText({});
  assertEquals(text.includes('trouble'), true);
});

Deno.test('sanitizeResponseBody_plainTextUnchanged', () => {
  assertEquals(sanitizeResponseBody('hello'), 'hello');
});

Deno.test('sanitizeResponseBody_extractsBodyFromJson', () => {
  const out = sanitizeResponseBody('{"body":"Line\\none"}');
  assertEquals(out, 'Line\none');
});

Deno.test('extractBody_prefersStringBody', () => {
  assertEquals(extractBody({ body: '  hi  ' }), 'hi');
});

Deno.test('extractBody_nestedObject', () => {
  assertEquals(extractBody({ body: { text: 'nested' } }), 'nested');
});

Deno.test('cleanParsedBody_unwrapsNestedJson', () => {
  const inner = JSON.stringify({ body: 'final' });
  const outer = JSON.stringify({ body: inner });
  assertEquals(cleanParsedBody({ body: outer }), 'final');
});
