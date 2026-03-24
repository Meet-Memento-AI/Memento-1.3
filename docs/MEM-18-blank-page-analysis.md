# MEM-18: App Launch Blank Page – Root Cause & Fix

## Problem

The app shows a blank screen on launch about 50% of the time for repeat (signed-in) users. It happens during the transition from WelcomeView to ContentView and is more likely on slower networks.

## Root Cause

There is a **race between auth restoration and view rendering**, with no explicit "auth loading" state.

### Previous Flow (Buggy)

1. App launches → `AuthViewModel` starts with `isAuthenticated = false`, `hasCompletedOnboarding = false`.
2. First frame → `Group` evaluates and chooses a branch:
   - `isAuthenticated && hasCompletedOnboarding` → ContentView
   - `isAuthenticated && !hasCompletedOnboarding` → OnboardingCoordinatorView
   - **Else** → WelcomeView
3. Because both flags are initially false, **WelcomeView is shown**.
4. `.task` runs → `authViewModel.initializeAuth()` calls `client.auth.session` (async, may hit network).
5. When it completes → state updates and SwiftUI switches to **ContentView**.
6. **During that switch** → WelcomeView is torn down and ContentView is built. That transition can briefly show **nothing** (blank screen).

### Why Intermittent (~50%)

`client.auth.session` can be:
- **Fast** when the session is cached locally.
- **Slower** when Supabase refreshes over the network.

So sometimes the transition is too fast to notice, sometimes slow enough to show a blank frame.

## Fix

Add an explicit `hasCheckedAuth` flag and show `LoadingView` until auth restoration completes.

### Changes

1. **AuthViewModel.swift**: Add `@Published var hasCheckedAuth = false`. Set it to `true` at the end of `initializeAuth()`.

2. **MeetMementoApp.swift**: Before choosing WelcomeView/OnboardingCoordinatorView/ContentView, check `!authViewModel.hasCheckedAuth` and show `LoadingView` until auth is known.

### New Flow (Fixed)

1. App launches → `hasCheckedAuth = false` → **LoadingView** is shown.
2. `.task` runs → `initializeAuth()` completes → `hasCheckedAuth = true`.
3. SwiftUI re-evaluates → shows ContentView (or WelcomeView/OnboardingCoordinatorView).
4. **No intermediate tear-down of WelcomeView** → no blank screen.

## Testing

| Scenario | How to test | Expected result |
|----------|-------------|-----------------|
| Repeat user (signed in) | Force quit, relaunch 10x | LoadingView briefly, then ContentView (no blank) |
| New user | Fresh install, open app | LoadingView briefly, then WelcomeView |
| Slow network | Network Link Conditioner → 3G, repeat user | LoadingView stays until auth ready, then ContentView |
