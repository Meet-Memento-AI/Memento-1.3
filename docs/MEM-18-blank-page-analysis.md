# MEM-18: App Gets Stuck on Blank Page – Analysis & Resolution Guide

## Executive Summary

The blank page occurs primarily for **repeat users** (users who already have an account) when opening the app. The root cause is a **race between auth session restoration and view rendering**, combined with the lack of an explicit "auth loading" state. The ~50% occurrence rate suggests intermittent timing—sometimes the transition is smooth, sometimes it exposes a brief blank state.

**Face ID is not involved** at app launch; it is only used during onboarding. The issue description’s mention of facial recognition is likely a red herring.

---

## 1. App Launch Flow (Current Behavior)

### Entry Point: `MeetMementoApp.swift`

```
App Launch
    → AuthViewModel created (isAuthenticated=false, hasCompletedOnboarding=false)
    → WindowGroup body renders
    → Group { if/else if/else } evaluates
    → First frame: Shows WelcomeView (because both flags are false)
    → .task { await authViewModel.initializeAuth() } runs AFTER first render
    → initializeAuth() calls client.auth.session (async, may hit network)
    → On success: isAuthenticated=true, hasCompletedOnboarding=true
    → SwiftUI re-renders → Switches to ContentView
```

### Routing Logic (MeetMementoApp.swift, lines 22–51)

| Condition | View Shown |
|-----------|------------|
| `isAuthenticated && hasCompletedOnboarding` | ContentView (main app) |
| `isAuthenticated && !hasCompletedOnboarding` | OnboardingCoordinatorView |
| Else (default) | WelcomeView |

---

## 2. Why the Blank Page Happens

### 2.1 Auth Check Runs After First Render

The `.task` modifier runs **after** the view’s first render. So:

- **Frame 1**: `WelcomeView` is shown (default unauthenticated state).
- **Frame 2+**: `initializeAuth()` runs asynchronously.
- **Frame N**: When it completes, state updates and SwiftUI switches to `ContentView`.

There is no explicit “checking auth” state. The app goes directly from `WelcomeView` to `ContentView` when auth is restored.

### 2.2 View Transition Gap (Primary Cause)

When SwiftUI switches from `WelcomeView` to `ContentView`:

1. `WelcomeView` is torn down.
2. `ContentView` is built (NavigationStack, ZStack, TopTabNavContainer, JournalView, etc.).
3. During this transition, SwiftUI may briefly show neither view, or a partially built hierarchy.

`ContentView` is heavy: it creates `EntryViewModel`, `JournalView`, `YourEntriesView`, and more. The first frame of `ContentView` can take a moment to render. That gap is what users see as a blank page.

### 2.3 Session Restoration Timing (Why ~50%)

`client.auth.session` in `AuthViewModel.initializeAuth()` can:

- Be fast when the session is cached locally.
- Be slower when Supabase refreshes the session over the network.
- Vary with network conditions.

So:

- **Fast path**: Quick transition, less chance of a visible blank.
- **Slow path**: Longer wait on `WelcomeView`, then a sudden switch to `ContentView`, increasing the chance of a visible transition gap.

The ~50% rate fits this intermittent timing.

### 2.4 No Auth Loading State

The app never shows a dedicated “checking auth” or splash state. It either shows:

- `WelcomeView` (before auth is known), or
- The final destination (`ContentView`, `OnboardingCoordinatorView`).

There is no intermediate loading UI to cover the transition.

---

## 3. What Is NOT Causing the Issue

### Face ID / Biometrics

- Face ID is only used in onboarding (`FaceIDView`, `OnboardingViewModel.useFaceID`).
- There is no Face ID check or unlock at app launch.
- The issue description’s mention of facial recognition is likely a guess.

### Scene Phase / Background

- There is no `@Environment(\.scenePhase)` or foreground/background handling.
- This does not cause the blank page, though adding it could help with session refresh when returning from background.

### ContentView Loading

- `YourEntriesView` shows a loading spinner when `isLoading && entries.isEmpty`.
- `JournalView.onAppear` triggers `loadEntriesIfNeeded()`.
- The blank page happens **before** or **during** the transition to `ContentView`, not during journal loading.

---

## 4. Resolution Guide

### Recommended Fix: Add an Explicit Auth Loading State

Introduce a `hasCheckedAuth` (or equivalent) flag and show a splash/loading view until auth is known. This avoids the abrupt switch from `WelcomeView` to `ContentView` and removes the visible blank gap.

#### Step 1: Add `hasCheckedAuth` to AuthViewModel

```swift
// AuthViewModel.swift
@Published var hasCheckedAuth = false  // New property

func initializeAuth() async {
    defer { hasCheckedAuth = true }  // Always set when done
    // ... existing logic ...
}
```

#### Step 2: Update MeetMementoApp Routing

```swift
// MeetMementoApp.swift
Group {
    if !authViewModel.hasCheckedAuth {
        // Show splash/loading until we know auth state
        LoadingView()  // or a minimal SplashView
            .useTheme()
            .useTypography()
    } else if authViewModel.isAuthenticated && authViewModel.hasCompletedOnboarding {
        ContentView()
            // ...
    } else if authViewModel.isAuthenticated && !authViewModel.hasCompletedOnboarding {
        OnboardingCoordinatorView()
            // ...
    } else {
        WelcomeView()
            // ...
    }
}
```

#### Step 3: Ensure LoadingView Has a Solid Background

`LoadingView` already uses `theme.background.ignoresSafeArea()`. Confirm it fully covers the screen so there is no transparent or empty area during the transition.

### Alternative: Run Auth Check Earlier

You could try to run `initializeAuth()` before the first render (e.g., in `init` or via an earlier entry point), but:

- SwiftUI’s `@main` app lifecycle makes this tricky.
- The comment in `MeetMementoApp` notes that running auth before UI can cause SIGKILL crashes.
- The loading-state approach is safer and aligns with common patterns.

### Optional: Scene Phase Handling

For robustness when returning from background:

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        Task { await authViewModel.initializeAuth() }
    }
}
```

This helps keep the session fresh but is not required to fix the blank page.

---

## 5. Files to Modify

| File | Change |
|------|--------|
| `MeetMemento/ViewModels/AuthViewModel.swift` | Add `hasCheckedAuth`, set it in `initializeAuth()` |
| `MeetMemento/MeetMementoApp.swift` | Add loading branch when `!hasCheckedAuth` |

---

## 6. Testing Checklist

After implementing the fix:

1. **Cold start (repeat user)**  
   - Kill app, relaunch.  
   - Expect: Splash/loading → ContentView.  
   - No blank page.

2. **Cold start (new user)**  
   - Fresh install or signed out.  
   - Expect: Splash/loading → WelcomeView.

3. **Slow network**  
   - Throttle network (e.g., Network Link Conditioner).  
   - Expect: Loading view until auth is known, then correct destination.

4. **Background → foreground**  
   - Background app, return.  
   - Expect: No regression; optional scene phase handling can improve session refresh.

---

## 7. Summary

| Aspect | Detail |
|--------|--------|
| **Root cause** | No auth loading state; visible gap during WelcomeView → ContentView transition |
| **Why repeat users** | They hit the ContentView path; new users stay on WelcomeView |
| **Why ~50%** | Variable timing of `client.auth.session` (cache vs network) |
| **Face ID** | Not involved at launch |
| **Fix** | Add `hasCheckedAuth` and show LoadingView until auth is known |
