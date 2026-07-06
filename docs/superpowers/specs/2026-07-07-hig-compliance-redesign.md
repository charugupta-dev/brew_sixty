# Design Spec: Apple HIG Compliance & UI Overhaul

**Date:** 2026-07-07  
**Status:** Approved  

This document specifies the design changes to align the app with Apple HIG standards for visual hierarchy, contrast, touch ergonomics, and native feel.

---

## 1. Background Masking & Contrast (Approved: Option A)

### Problem
Atmospheric background effects (live video wallpaper and particle embers/smoke) run behind sliders and text, causing contrast issues and visual clutter.

### Solution
* Implement a vertical gradient mask on `VideoWallpaperBackground` and `SmokeParticleOverlay` (within `SmokeBackgroundView.swift`) so that the animations/particles are only visible in the top 40% of the screen.
* The lower 60% of the screen will fade completely into a solid obsidian black color (`#0D0C0C`), creating a clean, high-contrast background for interactive parameters, sliders, forms, and bottom navigation.

---

## 2. Parameter Forms & Sliders

### A. Stepper & Weight Selector (Approved: Option A)
* Keep the giant weight value display and `[-]` / `[+]` stepper buttons in `SteppedWeightPicker.swift`.
* Hide the horizontal list of quick-select preset buttons (`12g`, `15g`, etc.) behind a clean, inline collapsible disclosure button (e.g., "Show Presets" / "Hide Presets" with a chevron icon). When collapsed, the visual footprint is reduced to zero.

### B. Slider Aesthetics (`PrecisionSlider.swift`)
* Increase the vertical track height from a thin line-art stroke to a standard rounded track (e.g., height `6`).
* Clearly differentiate the filled (active) track in primary copper from the unfilled (remaining) track in translucent white/gray.
* Remove min/max range text labels directly beneath the slider track to eliminate clutter. Move range information to the header label or SF Symbols.

### C. Visual Grouping (`MethodsView.swift`)
* Group the form sections into two semantic cards to break up visual monotony:
  * **Section 1: Dose & Yield** (Bean Weight, Target Water Ratio, Target Water Volume).
  * **Section 2: Time & Temperature** (Bloom Duration, Brew Temperature, Steep/Press Durations).

---

## 3. Touch Targets & Ergonomics

### Problem
Active brewing control buttons (`Reset` and `Skip Phase`) are low-contrast ghost buttons with sub-44x44 pt hit targets.

### Solution
* Increase the minimum touch target for `Reset` and `Skip Phase` buttons to **44x44 pt**.
* Style them as solid translucent capsule backdrops with higher-contrast text (`.secondaryLabel` equivalent) for secure tapping even in wet kitchen conditions.

---

## 4. Bottom Tab Bar Translucency

### Problem
The clear background tab bar floats ungrounded over the wallpaper and lacks native depth.

### Solution
* Configure the default `UITabBarAppearance` in `ContentView.swift` to use a standard translucent material blur (using UIKit's standard blur material or SwiftUI's `.ultraThinMaterial` styling).
* Ensure unselected tab items use crisp SF Symbols and have sufficient contrast against the blurred background.

---

## 5. Visual refinement

### A. Kettle & Brewer Graphics (`HomeView.swift`)
* Redraw the vector illustration paths of the brewer devices (V60 kettle, French Press plunger, Chemex outline, Aeropress plunger) using bolder, refined strokes that resemble Apple's premium SF Symbol design language.

### B. Header Hierarchy (`HomeView.swift`)
* Clean up the subtitle `Comfortable • Guided mode` by converting it to a clean, clickable capsule badge indicating the active guidance level.
