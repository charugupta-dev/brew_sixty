# Phase 1 Siri & App Intents Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete all missing features of Phase 1, specifically `AdjustRecipeIntent` (to mutate active drafts or standalone recipes) and `OpenMethodIntent` (filtering recipes by brewer).

**Architecture:** 
1. Expose `activeEditingDraft` in `BrewSessionStore` and bind to it in `RecipeEditorView` to support background adjustments while editing.
2. Add `RecipeAdjustmentOption` parameter and implement `applyAdjustment(_:)` on `RecipeDraft`.
3. Add `AdjustRecipeIntent` and map it to `Phase1IntentAction.adjustRecipe`.
4. Add `method` parameter to `ShowRecipesIntent` and handle filtering with a clean UI badge in `MethodsView`.
5. Add shortcuts phrases for the new parameters.

**Tech Stack:** SwiftUI, AppIntents, SwiftData

---

### Task 1: Implement Adjustment Logic on RecipeDraft

**Files:**
- Modify: `brew_sixty/brew_sixty/Model/RecipeDraft.swift`

- [ ] **Step 1: Add applyAdjustment**
  Define `RecipeAdjustmentType` and implement `applyAdjustment(_:)` mutating method on `RecipeDraft` to handle stronger/lighter cup dose changes, cup size scaling, temperature lowering, and bloom extension.

---

### Task 2: Implement AdjustRecipeIntent & update App Intents

**Files:**
- Modify: `brew_sixty/brew_sixty/AppIntents/Phase1BrewAppIntents.swift`
- Modify: `brew_sixty/brew_sixty/AppIntents/Phase1IntentExecutionService.swift`
- Modify: `brew_sixty/brew_sixty/Support/Phase1IntentActionStore.swift`

- [ ] **Step 1: Declare AdjustRecipeIntent**
  Add `RecipeAdjustmentOption` parameter enum and the `AdjustRecipeIntent` struct. Register it in `BrewSixtyShortcutsProvider` with phrases:
  * "Make this \(.$adjustment) in \(.applicationName)"
  * "Change recipe to \(.$adjustment) in \(.applicationName)"
  * "Adjust my V60 to \(.$adjustment) in \(.applicationName)"

- [ ] **Step 2: Add method filtering parameter to ShowRecipesIntent**
  Add `method` parameter (`BrewMethodOption?`) to `ShowRecipesIntent` and update phrases in `BrewSixtyShortcutsProvider`:
  * "Show my \(.$method) recipes in \(.applicationName)"
  * "Open \(.$method) setup in \(.applicationName)"

- [ ] **Step 3: Update Phase1IntentAction and execution mapping**
  Add `.adjustRecipe` case and optional `methodFilter` parameter to `.openRecipes` in `Phase1IntentAction`. Implement mapping in `Phase1IntentExecutionService`.

---

### Task 3: Bind active editing draft in BrewSessionStore & RecipeEditorView

**Files:**
- Modify: `brew_sixty/brew_sixty/ViewModel/BrewSessionStore.swift`
- Modify: `brew_sixty/brew_sixty/View/RecipeEditorView.swift`

- [ ] **Step 1: Declare activeEditingDraft**
  Add `var activeEditingDraft: RecipeDraft?` to `BrewSessionStore`.

- [ ] **Step 2: Sync draft in RecipeEditorView**
  In `RecipeEditorView.swift`, synchronize `draft` with `brewSessionStore.activeEditingDraft` on appear, on change of either, and clear it on disappear.

---

### Task 4: Handle Adjust and Open Filter in Views

**Files:**
- Modify: `brew_sixty/brew_sixty/ContentView.swift`
- Modify: `brew_sixty/brew_sixty/View/HomeView.swift`
- Modify: `brew_sixty/brew_sixty/View/MethodsView.swift`

- [ ] **Step 1: Process adjustRecipe action**
  In `ContentView`, if `adjustRecipe` intent action is received:
  * If `activeEditingDraft` is open, modify it and show banner.
  * If not, apply adjustment to the current/last recipe or default method, and request recipe composer to open with the draft.

- [ ] **Step 2: Support method filtering in MethodsView**
  Add `methodFilter` state (or bind to a filter in `BrewSessionStore`) in `MethodsView` and filter the query list. Display a closeable filter capsule badge at the top of the list if active.

---

### Task 5: Compilation and Verification

- [ ] **Step 1: Verify compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED
