# InsightsView Loading Experience – Improvement Plan

## 1. Current Behavior

- **On appear:** Only restores from in-memory cache (`syncDisplayFromCache()`). No API call on tab appear.
- **First time:** User sees “Pull down to load insights” until they pull-to-refresh or change month.
- **Cache:** Per-month in-memory cache (`insightCache["yyyy-MM"]`). API is called only on pull-to-refresh or date change (and only on cache miss).
- **Result:** First visit feels passive; user must pull or change date to see insights.

## 2. Goals

1. **Load the first time they appear** – When the user opens the Insights tab and there are entries for the selected month, trigger one automatic load if that month is not cached.
2. **Stay fixed after that** – Use cache on subsequent appears; no automatic refetch when switching back to the tab. Refetch only on explicit pull-to-refresh or month change.
3. **Snappy and optimized** – Immediate skeleton/placeholder, non-blocking load, minimal main-thread work, optional entry prefetch so the first load has data.

## 3. Detailed Plan

### 3.1 First-appear load (one-time per month)

- **Trigger:** When `InsightsView` appears and:
  - There is **no** cached insight for the current month (`!insightCache[currentMonthKey].exists`), and
  - There **are** entries for the selected month (`!entriesForSelectedMonth.isEmpty`), or we are about to load entries and will re-check.
- **Action:** Run a single async load for the current month (e.g. `loadForCurrentMonth()`). That will call the API once and cache; future appears for that month use cache only.
- **Do not:** Refetch on every `.onAppear`; only when cache is missing for the current month.

### 3.2 Ensure entries are available before first load

- **Problem:** If the user opens the app and switches straight to Insights, `entryViewModel.entries` may still be empty (Journal loads entries on its own appear).
- **Action:** When Insights appears, ensure entries are loaded first: e.g. `await entryViewModel.loadEntriesIfNeeded()` inside the same `.task` that decides whether to load insights. Then:
  - If `entriesForSelectedMonth.isEmpty` → show “No entries this month” or empty state; no API call.
  - If we have entries and no cache → call `loadForCurrentMonth()` once.

### 3.3 Use `.task` instead of `.onAppear` for async work

- **Why:** `.task` is lifecycle-bound and cancellable; when the view disappears the task is cancelled, avoiding wasted work and duplicate in-flight requests.
- **Implementation:** One `.task { }` that:
  1. Restores UI from cache synchronously (or at start of task on MainActor) so returning users see cached content immediately.
  2. Awaits `entryViewModel.loadEntriesIfNeeded()` so entries are available.
  3. If cache hit for current month → optionally run animation if needed; **no** API call.
  4. If cache miss and `!entriesForSelectedMonth.isEmpty` → call `await loadForCurrentMonth()` once (which will fetch and cache).

### 3.4 Keep cache behavior “fixed” after first load

- **No refetch on tab reappear:** After the first load, `insightCache[currentMonthKey]` is set. On subsequent appears, `syncDisplayFromCache()` (or equivalent at start of `.task`) restores `insight` and `entriesCount` from cache; no API call.
- **Refetch only when:**
  - User pulls to refresh (current behavior: refresh entries, then `loadForCurrentMonth()` – cache hit = no API, cache miss = one API call).
  - User changes month (current behavior: `updateSelectedDate()` → `loadForCurrentMonth()` – same).

### 3.5 Snappy UI

- **Immediate skeleton:** As soon as there are entries and no insight (or loading), show the existing skeleton/placeholder so the screen never looks “blank” while waiting.
- **No blocking:** All network and heavy work in async `loadForCurrentMonth()` / `fetchInsights()`; only small state updates on MainActor.
- **Optional:** Short debounce (e.g. 50–100 ms) before starting the first load so that rapid tab switches don’t trigger unnecessary work; optional and can be skipped for simplicity.

### 3.6 Edge cases

- **Entries empty:** After `loadEntriesIfNeeded()`, if `entryViewModel.entries.isEmpty` → show “No insights yet” empty state; do not call API.
- **Selected month has no entries:** If `entriesForSelectedMonth.isEmpty` → show “No entries this month” (or similar); do not call API.
- **View disappears mid-fetch:** `.task` cancellation will stop the async work; avoid updating state after cancellation (e.g. check `Task.isCancelled` or rely on SwiftUI not updating removed views).
- **Month change during first load:** Existing logic in `fetchInsights()` already caches by the key at start and only updates displayed insight if `currentMonthKey == key`; keep that.

## 4. Implementation Checklist

- [x] Replace `.onAppear` with a single `.task` for “restore cache + ensure entries + maybe load”.
- [x] In `.task`: call `syncDisplayFromCache()` (or apply cache to state) so returning users see cached content immediately.
- [x] In `.task`: `await entryViewModel.loadEntriesIfNeeded()` so entries are available before deciding to load insights.
- [x] In `.task`: if cache miss for current month and `!entriesForSelectedMonth.isEmpty`, call `await loadForCurrentMonth()` once.
- [x] Leave pull-to-refresh and month-change behavior unchanged (they already call `loadForCurrentMonth()` and respect cache).
- [x] Ensure skeleton/placeholder is shown whenever we have entries and (insight is nil or isLoadingInsight); no change if already correct.
- [ ] Remove or update any “Pull down to load insights” hint for the case where we are auto-loading (e.g. show only when not loading and no cache, or simplify to “Loading…” when `isLoadingInsight`).

## 5. Success Criteria

- First time user opens Insights (with entries for current month): one automatic load, then content appears and is cached.
- User switches away and back: content appears immediately from cache, no new API call.
- User pulls to refresh: entries refresh; insight refetched only if cache invalidated or not present for that month (current behavior).
- User changes month: insight for that month loads once (from cache if available, else API) and stays fixed for that month on subsequent visits.
