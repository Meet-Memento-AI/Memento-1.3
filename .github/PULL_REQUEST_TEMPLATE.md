## Summary

<!-- What changed and why (1–3 sentences). -->

## Testing

- [ ] I added or updated tests for behavior changes (unit / UI / Edge Function helpers as applicable).
- [ ] `xcodebuild -scheme MeetMemento -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' test` (adjust `OS` if your Xcode only lists another runtime; `xcodebuild -showdestinations -scheme MeetMemento`)
- [ ] `cd supabase/functions/chat && deno test lib_test.ts` (if chat `lib.ts` / `index.ts` changed)
