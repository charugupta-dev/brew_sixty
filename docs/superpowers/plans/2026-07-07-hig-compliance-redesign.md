# Apple HIG Compliance & UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-align the coffee brewing app's UI/UX with Apple Human Interface Guidelines by reducing background visual noise, improving touch ergonomics to 44x44 pt, cleaning up redundant weight presets, upgrading slider tracks, grouping settings parameters, and refining tab bar translucency.

**Architecture:** Use a linear gradient mask on video/smoke overlay backgrounds to fade them into solid obsidian dark space in the lower half of the screen. Standardize tab bar appearance with standard system blur materials. Use collapsible states for weight presets and group parameters into semantic card panels.

**Tech Stack:** SwiftUI, SwiftData, UIKit appearances.

---

### Task 1: Background Contrast Masking and Translucent Tab Bar

**Files:**
* Modify: `brew_sixty/brew_sixty/View/VideoWallpaperBackground.swift`
* Modify: `brew_sixty/brew_sixty/View/SmokeBackgroundView.swift`
* Modify: `brew_sixty/brew_sixty/ContentView.swift`

- [ ] **Step 1: Apply gradient mask to video wallpaper**
  Modify [VideoWallpaperBackground.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/VideoWallpaperBackground.swift) to add a black background layer underneath and mask the looping video to the top 40% of the screen.
  Replace lines 78-98 with:
  ```swift
  var body: some View {
      ZStack {
          Color(red: 0.05, green: 0.05, blue: 0.05) // Deep solid obsidian
          
          LoopingVideoPlayerView()
              .blur(radius: style.blurRadius)
              .mask(
                  LinearGradient(
                      colors: [.white, .white.opacity(0.8), .clear],
                      startPoint: .top,
                      endPoint: .center
                  )
              )
              .opacity(0.4) // Softened to avoid visual noise

          Color.black.opacity(style.baseDimOpacity)
      }
      .ignoresSafeArea()
      .allowsHitTesting(false)
  }
  ```

- [ ] **Step 2: Apply gradient mask to particle overlay canvas**
  Modify [SmokeBackgroundView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/SmokeBackgroundView.swift) to mask the canvas rendering to the top half of the screen.
  Replace lines 158-215 with:
  ```swift
  var body: some View {
      TimelineView(.animation) { timelineContext in
          GeometryReader { geometry in
              Canvas { context, canvasSize in
                  system.update(now: timelineContext.date, bounds: canvasSize)
                  
                  // Render smoke
                  for p in system.particles {
                      let rect = CGRect(
                          x: p.x - p.scale / 2,
                          y: p.y - p.scale / 2,
                          width: p.scale,
                          height: p.scale
                      )
                      
                      let shading = GraphicsContext.Shading.radialGradient(
                          Gradient(colors: [p.color.opacity(p.opacity), p.color.opacity(0)]),
                          center: CGPoint(x: p.x, y: p.y),
                          startRadius: 0,
                          endRadius: p.scale / 2
                      )
                      
                      context.fill(Path(ellipseIn: rect), with: shading)
                  }
                  
                  // Render embers
                  for e in system.embers {
                      let rect = CGRect(
                          x: e.x - e.size / 2,
                          y: e.y - e.size / 2,
                          width: e.size,
                          height: e.size
                      )
                      
                      context.fill(Path(ellipseIn: rect), with: .color(e.color.opacity(e.opacity)))
                  }
              }
              .mask(
                  LinearGradient(
                      colors: [.white, .white.opacity(0.8), .clear],
                      startPoint: .top,
                      endPoint: .center
                  )
              )
          }
      }
      .allowsHitTesting(false)
      .ignoresSafeArea()
  }
  ```

- [ ] **Step 3: Replace transparent tab bar with default translucent material**
  Modify [ContentView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/ContentView.swift) to restore standard iOS translucent materials to the tab bar.
  Replace lines 14-23 with:
  ```swift
  init() {
      let appearance = UITabBarAppearance()
      appearance.configureWithDefaultBackground() // Restore translucent system glass
      
      UITabBar.appearance().standardAppearance = appearance
      UITabBar.appearance().scrollEdgeAppearance = appearance
  }
  ```

- [ ] **Step 4: Verify Compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit changes**
  ```bash
  git commit -am "style: mask background visual noise to top 40% and restore translucent tab bar"
  ```

---

### Task 2: Slider Visual Overhaul and Stepper Presets Disclosure

**Files:**
* Modify: `brew_sixty/brew_sixty/View/PrecisionSlider.swift`
* Modify: `brew_sixty/brew_sixty/View/SteppedWeightPicker.swift`

- [ ] **Step 1: Increase PrecisionSlider vertical track height and styling**
  Modify [PrecisionSlider.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/PrecisionSlider.swift) to use a thicker track and cleaner visual states.
  Replace lines 29-47 with:
  ```swift
  ZStack(alignment: .leading) {
      Capsule()
          .fill(Color.white.opacity(0.08))
          .frame(height: 10) // Thicker track
          .overlay(
              Capsule()
                  .stroke(Color.white.opacity(0.12), lineWidth: 1)
          )
      
      Capsule()
          .fill(
              LinearGradient(
                  colors: [Color.primaryCopper, Color.brushedCopper],
                  startPoint: .leading,
                  endPoint: .trailing
              )
          )
          .frame(width: clampedProgress * width, height: 10)
  ```

- [ ] **Step 2: Add collapsible presets drawer to SteppedWeightPicker**
  Modify [SteppedWeightPicker.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/SteppedWeightPicker.swift) to hide weight quick-select pills behind a collapsible button.
  Replace lines 3-15 with:
  ```swift
  struct SteppedWeightPicker: View {
      @Binding var value: Double
      let range: ClosedRange<Double> = AppConstants.Pickers.steppedWeightRange
      let step: Double = AppConstants.Pickers.steppedWeightStep
      let presets: [Double] = AppConstants.Pickers.steppedWeightPresets
      let onInteraction: (() -> Void)?
      
      @State private var showPresets = false // Collapsible disclosure state

      init(value: Binding<Double>, onInteraction: (() -> Void)? = nil) {
          _value = value
          self.onInteraction = onInteraction
      }
      
      var body: some View {
          VStack(spacing: 12) {
  ```
  And replace lines 65-94 (the preset list ScrollView) with:
  ```swift
              Button {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                      showPresets.toggle()
                  }
              } label: {
                  HStack(spacing: 4) {
                      Text(showPresets ? "Hide Presets" : "Quick Presets")
                      Image(systemName: showPresets ? "chevron.up" : "chevron.down")
                  }
                  .font(.system(size: 11, weight: .bold, design: .monospaced))
                  .foregroundStyle(Color.primaryCopper)
                  .padding(.vertical, 4)
                  .padding(.horizontal, 10)
                  .background(Color.white.opacity(0.04))
                  .cornerRadius(12)
              }
              .buttonStyle(.plain)
              
              if showPresets {
                  ScrollView(.horizontal, showsIndicators: false) {
                      HStack(spacing: 8) {
                          ForEach(presets, id: \.self) { preset in
                              let isSelected = abs(value - preset) < 0.01
                              Button {
                                  withAnimation(.easeOut(duration: 0.15)) {
                                      onInteraction?()
                                      value = preset
                                      UISelectionFeedbackGenerator().selectionChanged()
                                  }
                              } label: {
                                  Text(String(format: "%.0fg", preset))
                                      .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .monospaced))
                                      .foregroundStyle(isSelected ? .black : .white.opacity(0.65))
                                      .padding(.horizontal, 14)
                                      .padding(.vertical, 6)
                                      .background(
                                          Capsule()
                                              .fill(isSelected ? Color.primaryCopper : Color.white.opacity(0.04))
                                      )
                                      .overlay(
                                          Capsule()
                                              .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                      )
                              }
                          }
                      }
                      .padding(.top, 4)
                  }
                  .transition(.opacity.combined(with: .move(edge: .top)))
              }
  ```

- [ ] **Step 3: Verify Compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit changes**
  ```bash
  git commit -am "style: upgrade precision slider track height and hide quick-select pills behind disclosure button"
  ```

---

### Task 3: Methods Parameters Grouping and Label Clean-up

**Files:**
* Modify: `brew_sixty/brew_sixty/View/MethodsView.swift`

- [ ] **Step 1: Clean up redundant floating range text labels under sliders**
  Modify [MethodsView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/MethodsView.swift) to remove the small floating text labels underneath the sliders.
  Delete lines 152-159 (Water Ratio range labels).
  Delete lines 178-185 (Water Volume range labels).
  Delete lines 226-233 (Steep Duration range labels).
  Delete lines 254-261 (Press Duration range labels).

- [ ] **Step 2: Group parameters into Dose & Yield vs. Time & Temp SectionCards**
  Group parameters in [MethodsView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/MethodsView.swift).
  Wrap the Bean Weight, Ratio, and Water Volume parameter VStacks in a custom translucent card representing **Dose & Yield**.
  Wrap the Bloom Duration, Steep Duration, Press Duration, and Temperature Picker in a card representing **Time & Temperature**.
  Use this structural card overlay wrapper:
  ```swift
  struct SectionCard<Content: View>: View {
      let title: String
      let content: Content
      
      init(_ title: String, @ViewBuilder content: () -> Content) {
          self.title = title
          self.content = content()
      }
      
      var body: some View {
          VStack(alignment: .leading, spacing: 14) {
              Text(title.uppercased())
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(Color.primaryCopper)
                  .tracking(1.5)
                  .padding(.bottom, 4)
              
              content
          }
          .padding(16)
          .background(
              RoundedRectangle(cornerRadius: 16)
                  .fill(Color.white.opacity(0.03))
          )
          .overlay(
              RoundedRectangle(cornerRadius: 16)
                  .stroke(Color.white.opacity(0.06), lineWidth: 1)
          )
          .padding(.horizontal, 16)
      }
  }
  ```
  Add this helper struct at the bottom of `MethodsView.swift`.
  And rebuild the main ScrollView content around line 117 to group views inside `SectionCard("Dose & Yield")` and `SectionCard("Time & Temperature")`.

- [ ] **Step 3: Verify Compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit changes**
  ```bash
  git commit -am "style: clean up slider range labels and group settings parameters into SectionCards"
  ```

---

### Task 4: Touch Target Upgrades and Refined Controls

**Files:**
* Modify: `brew_sixty/brew_sixty/View/HomeView.swift`

- [ ] **Step 1: Upgrade Reset and Skip button sizes to 44x44 pt**
  Modify [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift) to ensure buttons are at least 44pt in height/width and have high contrast text.
  Update the bottom control bar HStack where `Reset` and `Skip` buttons are rendered, setting a custom `.frame(minWidth: 80, minHeight: 44)` and a capsule background frame.
  Example code:
  ```swift
  Button {
      viewModel.reset()
  } label: {
      Text("Reset")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.white.opacity(0.85))
          .frame(minWidth: 80, minHeight: 44)
          .background(Color.white.opacity(0.08))
          .cornerRadius(22)
          .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.12), lineWidth: 1))
  }
  ```

- [ ] **Step 2: Redraw device silhouettes using bold premium strokes**
  Modify [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift) to increase vector graphic stroke weights from `1.5` / `1.8` to `2.2` or `2.5` to look like bold SF Symbols.

- [ ] **Step 3: Convert guidance subtitle to a clickable capsule badge**
  Modify the `greetingText` / `profileSummaryText` Stack in [HomeView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/HomeView.swift) so that `Comfortable • Guided mode` is wrapped in a clickable capsule chip:
  ```swift
  Button {
      showProfileSheet = true
  } label: {
      HStack(spacing: 4) {
          Image(systemName: "hand.tap.fill")
              .font(.system(size: 8))
          Text(profileSummaryText)
      }
      .font(.system(size: 10, weight: .bold, design: .monospaced))
      .foregroundStyle(Color.primaryCopper)
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(Color.primaryCopper.opacity(0.12))
      .cornerRadius(10)
  }
  .buttonStyle(.plain)
  ```

- [ ] **Step 4: Verify Compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit changes**
  ```bash
  git commit -am "style: enlarge Reset/Skip touch targets to 44pt and refine guidance subtitle badge"
  ```

---

### Task 5: Profile View Contrast Fills

**Files:**
* Modify: `brew_sixty/brew_sixty/View/ProfileSetupView.swift`

- [ ] **Step 1: Elevate text field background and dim unselected options**
  Modify [ProfileSetupView.swift](file:///Users/charu/brew_sixty/brew_sixty/brew_sixty/View/ProfileSetupView.swift) to set high-contrast bounds for the text input and properly dim unselected preference cards to `.secondaryLabel` (opacity 0.6).
  For input field:
  ```swift
  TextField("Enter name", text: $name)
      .padding()
      .background(Color.white.opacity(0.08)) // High contrast fill
      .cornerRadius(12)
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
  ```
  For unselected card option titles/texts, apply `.foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.6))`.

- [ ] **Step 2: Verify Compilation**
  Run: `xcodebuild -project brew_sixty.xcodeproj -scheme brew_sixty -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build`
  Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit changes**
  ```bash
  git commit -am "style: elevate profile text field contrast and dim unselected option texts"
  ```
