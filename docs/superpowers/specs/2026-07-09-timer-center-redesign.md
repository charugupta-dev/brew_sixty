# Design Spec: Timer Circle Center Redesign (Option A)

We are refining the active timer center HUD area in `HomeView` to replace the boxy quote card overlay with a floating text design that integrates naturally with the coffee device silhouettes and particle wallpaper backgrounds.

---

## Proposed Changes

### [Component] Home View Overlays

#### [MODIFY] [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift)

- Refactor `WaitStateCard` to remove card boundaries (border overlay, background linear gradient, and backing shadows).
- Display a clean, boundary-free `VStack` layout.
- Apply high-contrast text shadows (`.shadow(color: .black.opacity(...), radius: ... )`) on the title and message strings to maintain readability against dynamic wallpaper smoke and ember streams.
- Ensure safe uppercase conversion using `.localizedUppercase`.

---

## Verification Plan

### Automated Tests
- Build verification to ensure compiler flags pass.

### Manual Verification
- Deploying the app on simulator and validating that the text floats cleanly inside the timer circle without container boundaries.
