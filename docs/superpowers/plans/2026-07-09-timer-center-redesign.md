# Timer Circle Center Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the wait/bloom phase timer overlay inside the circular progress ring from a boxy card to a boundary-free floating text HUD (Option A).

**Architecture:** Refactor `WaitStateCard` to remove container borders, gradients, and backgrounds. Apply text shadows to ensure legibility over looping background videos and embers.

**Tech Stack:** SwiftUI, SwiftData, iOS 17+

---

### Task 1: WaitStateCard Re-styling

**Files:**
- Modify: `brew_sixty/brew_sixty/View/HomeView.swift:1117-1156`

- [ ] **Step 1: Verify current build succeeds**

  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 2: Replace WaitStateCard container styling with floating text HUD**

  Modify [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift) to replace the existing `WaitStateCard` implementation (lines 1117-1156) with:
  ```swift
  private struct WaitStateCard: View {
      let title: String
      let message: String
  
      var body: some View {
          VStack(spacing: 8) {
              Text(title.localizedUppercase)
                  .font(.system(size: 10, weight: .bold, design: .rounded))
                  .tracking(1.5)
                  .foregroundStyle(Color.primaryCopper)
                  .shadow(color: .black.opacity(0.40), radius: 2, x: 0, y: 1)
  
              Text(message)
                  .font(.system(size: 18, weight: .semibold, design: .rounded))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(Color.coffeeCream)
                  .fixedSize(horizontal: false, vertical: true)
                  .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1.5)
          }
          .padding(.horizontal, 12)
      }
  }
  ```

- [ ] **Step 3: Run the build to verify compilation**

  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit changes**

  Run:
  ```bash
  git commit -am "style: redesign timer circle center with floating text HUD (Option A)"
  ```
