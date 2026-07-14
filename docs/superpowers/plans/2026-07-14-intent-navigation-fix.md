# App Intent Navigation Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the App Intent navigation routing by replacing flaky `UserDefaults` notifications with a native SwiftUI `@AppStorage` binder to ensure reactive view state transitions.

**Architecture:** Expose the `UserDefaults` key from `Phase1IntentActionStore` and bind to it using `@AppStorage` in `ContentView`, `HomeView`, and `MethodsView`. Use SwiftUI's `.onChange(of: pendingActionData)` to reactively switch tabs and execute actions, eliminating race conditions when the app is launched or resumed from background shortcuts.

**Tech Stack:** SwiftUI, AppIntents, SwiftData

---

### Task 1: Expose Key in Phase1IntentActionStore

**Files:**
- Modify: `brew_sixty/brew_sixty/Support/Phase1IntentActionStore.swift:44-48`

- [ ] **Step 1: Expose the key constant**
  Modify [Phase1IntentActionStore.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/Support/Phase1IntentActionStore.swift) to change the visibility of the `key` constant so it can be accessed in `@AppStorage`.
  Replace lines 44-48 with:
  ```swift
  enum Phase1IntentActionStore {
      static let key = "phase1.intent.action"
  ```

---

### Task 2: Reactively bind and transition in ContentView

**Files:**
- Modify: `brew_sixty/brew_sixty/ContentView.swift:75-99`

- [ ] **Step 1: Add AppStorage property and transition onChange**
  Modify [ContentView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/ContentView.swift) to bind to the intent action data using `@AppStorage` and use `.onChange` instead of `NotificationCenter` observations.
  Replace lines 75-99 with:
  ```swift
      @AppStorage(Phase1IntentActionStore.key) private var pendingActionData: Data?

      var body: some View {
          ZStack {
              // ... existing body ...
          }
          .preferredColorScheme(.dark)
          .fullScreenCover(...)
          .onAppear(perform: applyPendingIntentDestinationIfNeeded)
          .onChange(of: scenePhase) { _, phase in
              guard phase == .active else { return }
              applyPendingIntentDestinationIfNeeded()
          }
          .onChange(of: showLaunchScreen) { _, isShowing in
              guard !isShowing else { return }
              applyPendingIntentDestinationIfNeeded()
          }
          .onChange(of: pendingActionData) { _, _ in
              applyPendingIntentDestinationIfNeeded()
          }
          .animation(.spring(response: 0.32, dampingFraction: 0.82), value: brewSessionStore.intentHandoffBanner)
      }

      private func applyPendingIntentDestinationIfNeeded() {
          guard !showLaunchScreen, let data = pendingActionData else { return }
          guard let action = try? JSONDecoder().decode(Phase1IntentAction.self, from: data) else { return }

          switch action.destination {
          case .brew:
              selectedTab = .brew
          case .recipes:
              selectedTab = .recipes
          }
      }
  ```

---

### Task 3: Reactively process actions in HomeView

**Files:**
- Modify: `brew_sixty/brew_sixty/View/HomeView.swift`

- [ ] **Step 1: Bind AppStorage and handle transient/saved template transitions**
  Modify [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift) to bind to `@AppStorage(Phase1IntentActionStore.key)` and safely consume the action without losing it on initial query loads.
  Implement the following:
  ```swift
      @AppStorage(Phase1IntentActionStore.key) private var pendingActionData: Data?
  ```
  And modify the `applyPendingIntentActionIfNeeded()` and lifecycle blocks to use `.onChange(of: pendingActionData)` and only delete `pendingActionData` when the template is successfully resolved.

---

### Task 4: Reactively process actions in MethodsView

**Files:**
- Modify: `brew_sixty/brew_sixty/View/MethodsView.swift`

- [ ] **Step 1: Bind AppStorage and handle recipe destination transitions**
  Modify [MethodsView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/MethodsView.swift) to bind to `@AppStorage(Phase1IntentActionStore.key)` and use `.onChange` for routing.

---

### Task 5: Compilation and Verification

- [ ] **Step 1: Verify compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED
