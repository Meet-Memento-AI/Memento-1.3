# MEM-23: Accessibility audit and WCAG 2 AA plan

This document records the accessibility audit performed for Linear issue MEM-23 and the roadmap for keeping Memento at **WCAG 2 Level AA** (and aligned with **Apple Human Interface Guidelines** for the iOS app).

## Latest commit reviewed

**`9bd4171`** — `fix(MEM-18): gate root UI on hasCheckedAuth until auth resolves`

- **Scope:** `MeetMementoApp.swift`, `AuthViewModel.swift`, `WelcomeView.swift`, and analysis notes. No direct accessibility API changes in that commit.
- **Accessibility note:** Gating the root UI on `hasCheckedAuth` avoids a transient blank or wrong screen during auth resolution, which reduces confusion for **all users** and supports predictable focus and VoiceOver flow once the correct view appears.

## Automated audit (static HTML)

**Tool:** [axe-core](https://github.com/dequelabs/axe-core) CLI 4.11.2 (Chrome headless), `file://` URLs.

**Pages:** `support.html`, `docs/index.html`, `docs/privacy.html`, `docs/terms.html`.

**Initial findings (before fixes):**

| Page            | Main issues |
|-----------------|-------------|
| `support.html`  | Link **color contrast** on light backgrounds; missing **`<main>`** landmark; content not in landmarks |
| `docs/index.html` | Blue button text vs white below AA; landmarks |
| `docs/privacy.html` / `docs/terms.html` | Link contrast; landmarks |

**After fixes:** **0 axe violations** on all four pages.

Changes applied: semantic `<main id="main-content">`, skip link, WCAG-AA-safe link colors (e.g. `#3730a3` / `#0051d5`), underlined inline links in legal copy where required, and primary button styling with sufficient contrast.

**Limitation:** axe reports that only a fraction of issues are detectable automatically; manual testing remains mandatory.

## iOS app (SwiftUI) — current strengths

The codebase already includes meaningful accessibility work:

- **VoiceOver:** `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, `accessibilityIdentifier` (tests), combined elements where appropriate.
- **Motion:** `accessibilityReduceMotion` on loading and summary components.
- **Charts:** `PercentageBarChart` uses dedicated tokens and VoiceOver summaries.
- **Decorative content:** Video backgrounds hidden from accessibility tree.
- **Design tokens:** `Theme.swift` documents WCAG-oriented contrast intent for semantic colors.

## Roadmap toward sustained WCAG 2 AA

### 1. Static web (GitHub Pages / marketing)

- [x] Fix axe-reported issues on support and legal pages (this iteration).
- [ ] Add a short **CI check** (e.g. axe CLI on `file://` or a static server in CI) so regressions fail the build.
- [ ] Re-audit when styles or copy change.

### 2. iOS app — systematic coverage

| Area | Actions |
|------|--------|
| **Perceivable** | Audit **Dynamic Type** end-to-end; fix truncation and clipping. Verify **color contrast** for custom colors, gradients, and glass effects (especially muted text on blurred backgrounds). |
| **Operable** | **Keyboard / external keyboard** on iPad; **Voice Control** labels; ensure all tappable targets meet minimum size and spacing. |
| **Understandable** | Consistent navigation and heading structure where SwiftUI exposes structure; clear error and loading states. |
| **Robust** | Maintain `accessibilityIdentifier` for UI tests; keep accessibility strings localizable when adding `Strings` / localization. |

### 3. Tools and process

- **Xcode:** Accessibility Inspector (audit, contrast, VoiceOver quick nav), **Simulator VoiceOver** smoke tests on critical flows (welcome, journal, chat, insights, settings, lock screen).
- **Optional:** UI tests with accessibility identifiers; snapshot or manual checklist per release.
- **Documentation:** Keep this file updated when the audit process or tooling changes.

### 4. “Green lines” / platform checks

- Interpret **green lines** in Accessibility Inspector as **indicators of issues to investigate**, not a single pass/fail gate—combine with VoiceOver walkthroughs and contrast checks.
- Track **Reduce Transparency** / **Increase Contrast** (and related settings) where Liquid Glass or blur is used.

## Next steps (recommended order)

1. Add **CI axe** (or equivalent) for static HTML in this repo.
2. Schedule a **VoiceOver pass** on the five core flows above with Dynamic Type at **extra-extra-large**.
3. **Contrast audit** on non-token colors (charts, marketing gradients, third-party UI).
4. Optional: **Accessibility section** in release checklist (copy in issue/PR template).

---

*Last updated: April 7, 2026*
