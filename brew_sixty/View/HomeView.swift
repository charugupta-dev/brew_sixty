import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrewTemplate.createdAt, order: .forward) private var templates: [BrewTemplate]
    @AppStorage(ProfilePreferences.Keys.name) private var profileName = ""
    @AppStorage(ProfilePreferences.Keys.experienceLevel) private var experienceLevelRaw = ProfileExperienceLevel.justStarting.rawValue
    @AppStorage(ProfilePreferences.Keys.guidanceMode) private var guidanceModeRaw = GuidanceMode.guided.rawValue
    
    @Binding var selectedTab: ContentView.Tab
    @State private var activeIndex: Int = 0
    @State private var isAnimating = false
    @State private var showProfileSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 64
            let cardToTabBarSpacing: CGFloat = 30
            
            // Map SwiftData templates dynamically to HomeBrewViewModel instances
            let viewModels: [HomeBrewViewModel] = templates.map { template in
                HomeBrewViewModel(template: template)
            }
            
            ZStack {
                VideoWallpaperBackground(style: .hero)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.system(.title3, design: .serif))
                                .fontWeight(.medium)
                                .foregroundStyle(Color.coffeeCream.opacity(0.72))

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
                        }

                        Spacer()

                        Button {
                            showProfileSheet = true
                        } label: {
                            ProfileAvatarView(name: profileName)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 6)
                    
                    if viewModels.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.primaryCopper)
                                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                .scaleEffect(isAnimating ? 1.05 : 0.95)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                        isAnimating = true
                                    }
                                }
                            
                            VStack(spacing: 8) {
                                Text(AppConstants.Text.emptyCanvasTitle)
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.coffeeCream)
                                
                                Text(AppConstants.Text.emptyCanvasDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            
                            Button {
                                selectedTab = .methods
                            } label: {
                                Text(AppConstants.Text.craftFirstRecipe)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.08))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.primaryCopper, Color.brushedCopper],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(28)
                            }
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        GeometryReader { cardProxy in
                            let cardHeight = max(cardProxy.size.height - cardToTabBarSpacing, 0)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<viewModels.count, id: \.self) { idx in
                                        let vm = viewModels[idx]
                                        LiveTimerCard(viewModel: vm)
                                            .frame(width: cardWidth, height: cardHeight)
                                            .scaleEffect(activeIndex == idx ? 1.0 : 0.92)
                                            .id(idx)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .frame(height: cardHeight, alignment: .top)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollPosition(id: Binding(
                                get: { activeIndex },
                                set: { if let val = $0 { activeIndex = val } }
                            ))
                            .safeAreaPadding(.horizontal, 32)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSetupView(mode: .edit)
        }
    }

    private var greetingText: String {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? AppConstants.Text.helloFallback : "Hello, \(trimmedName)"
    }

    private var profileSummaryText: String {
        let experience = ProfileExperienceLevel(rawValue: experienceLevelRaw)?.title ?? ProfileExperienceLevel.justStarting.title
        let guidance = GuidanceMode(rawValue: guidanceModeRaw)?.title ?? GuidanceMode.guided.title
        return "\(experience) • \(guidance) mode"
    }
}

private struct ProfileAvatarView: View {
    let name: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.primaryCopper.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            if initials.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryCopper)
            } else {
                Text(initials)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryCopper)
            }
        }
        .frame(width: 36, height: 36)
    }

    private var initials: String {
        let parts = name
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
            .compactMap { $0.first }

        return String(parts)
    }
}

@MainActor
struct LiveTimerCard: View {
    let viewModel: HomeBrewViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Inner Timer Card Container wrapping the timer circle, Kettle canvas animation, and overlay text
                VStack(spacing: 10) {
                    TimerCircleView(viewModel: viewModel)
                    
                    // Recipe info overlays
                    VStack(spacing: 6) {
                        Text(formatTime(viewModel.elapsed > 0 ? viewModel.elapsed : viewModel.totalDuration))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.coffeeCream)
                        
                        HStack(spacing: 8) {
                            let targetWaterStr = "\(Int(viewModel.targetWater))g"
                            let doseStr = viewModel.beanWeight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(viewModel.beanWeight))g" : String(format: "%.1fg", viewModel.beanWeight)
                            
                            Text("\(viewModel.method.rawValue.lowercased()) - Target: \(targetWaterStr) - \(doseStr)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.primaryCopper)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                
                PhaseStackPickerView(phases: phases, selectedIndex: pickerPhaseIndex)
                    .padding(.horizontal, 16)
                
                // Start / Pause Brew button
                Button {
                    viewModel.toggleTimer()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.subheadline)
                        Text(viewModel.isRunning ? AppConstants.Text.pauseBrew : AppConstants.Text.startBrew)
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.08))
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(28)
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
                
                // Reset & Skip buttons shown only when timer is running or has elapsed
                if viewModel.isRunning || viewModel.elapsed > 0 {
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button {
                            viewModel.resetTimer()
                        } label: {
                            Text(AppConstants.Text.reset)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(minWidth: 100, minHeight: 44)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(22)
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            viewModel.skipPhase()
                        } label: {
                            Text(AppConstants.Text.skipPhase)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(minWidth: 100, minHeight: 44)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(22)
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding()
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.UI.homeCardCornerRadius)
                .fill(Color(red: 0.10, green: 0.09, blue: 0.09).opacity(AppConstants.UI.cardOpacity))
        )
        .liquidGlassBorder(cornerRadius: 24)
    }
    
    
    
    private var phases: [BrewPhase] {
        switch viewModel.method {
        case .v60, .chemex:
            let bloom = viewModel.bloomDuration
            if bloom > 0 {
                return [
                    BrewPhase(title: "Bloom", description: "Swirl gently to saturate grounds", duration: "\(Int(bloom))s", icon: "stopwatch", waterAmount: "to \(formatGrams(viewModel.bloomWater))"),
                    BrewPhase(title: "First Pour", description: "Pour in circular spiral motion", duration: "60s", icon: "drop", waterAmount: "to \(formatGrams(viewModel.firstPourWater))"),
                    BrewPhase(title: "Final Drawdown", description: "Let the water draw down completely", duration: "Ready", icon: "hourglass", waterAmount: "to \(formatGrams(viewModel.targetWater))")
                ]
            } else {
                return [
                    BrewPhase(title: "First Pour", description: "Pour in circular spiral motion", duration: "60s", icon: "drop", waterAmount: "to \(formatGrams(viewModel.firstPourWater))"),
                    BrewPhase(title: "Final Drawdown", description: "Let the water draw down completely", duration: "Ready", icon: "hourglass", waterAmount: "to \(formatGrams(viewModel.targetWater))")
                ]
            }
        case .frenchPress:
            let steep = viewModel.customSteepDuration ?? 240.0
            let plunge = viewModel.customPressDuration ?? 15.0
            return [
                BrewPhase(title: "Steep", description: "Let it sit to extract flavors", duration: "\(Int(steep))s", icon: "stopwatch", waterAmount: "to \(formatGrams(viewModel.targetWater))"),
                BrewPhase(title: "Plunge", description: "Press down slowly and steadily", duration: "\(Int(plunge))s", icon: "hourglass", waterAmount: nil)
            ]
        case .aeropress:
            let steep = viewModel.customSteepDuration ?? 60.0
            let press = viewModel.customPressDuration ?? 30.0
            return [
                BrewPhase(title: "Steep", description: "Let it sit to extract flavors", duration: "\(Int(steep))s", icon: "stopwatch", waterAmount: "to \(formatGrams(viewModel.targetWater))"),
                BrewPhase(title: "Press", description: "Press down slowly and steadily", duration: "\(Int(press))s", icon: "hourglass", waterAmount: nil)
            ]
        }
    }
    
    private var pickerPhaseIndex: Int {
        let lastIndex = max(phases.count - 1, 0)
        if viewModel.activePhaseIndex < 0 {
            return lastIndex
        }
        
        return min(viewModel.activePhaseIndex, lastIndex)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatGrams(_ value: Double) -> String {
        "\(Int(value.rounded()))g"
    }
}

@MainActor
struct TimerCircleView: View {
    let viewModel: HomeBrewViewModel
    
    var body: some View {
        TimelineView(.animation) { context in
            let progress = viewModel.getProgress()
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 10)
                    .frame(width: 260, height: 260)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryCopper, Color.brushedCopper.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                
                // Canvas Animation for Kettle pouring or French Press Plunging
                Canvas { ctx, size in
                    let time = context.date.timeIntervalSince1970
                    let baseSize: CGFloat = 200
                    let scale = min(size.width, size.height) / baseSize * 1.15
                    let strokeColor = Color.coffeeCream.opacity(0.92)
        
                    
                    if viewModel.method == .v60 || viewModel.method == .chemex {
                        var scaledCtx = ctx
                        scaledCtx.translateBy(
                            x: (size.width - (baseSize * scale)) / 2,
                            y: (size.height - (baseSize * scale)) / 2
                        )
                        scaledCtx.scaleBy(x: scale, y: scale)
                        
                        // Gold gradient for paths
                        let goldGradient = GraphicsContext.Shading.linearGradient(
                            Gradient(colors: [Color.primaryCopper, Color.brushedCopper]),
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: 200, y: 200)
                        )
                        
                        let isRunning = viewModel.isRunning
                        
                        let isChemex = viewModel.method == .chemex
                        let speedMult = isChemex ? 1.4 : 3.5
                        let ampX = isChemex ? 3.0 : 8.0
                        let ampY = isChemex ? 1.5 : 4.0
                        let rotAmp = isChemex ? 1.0 : 3.0
                        
                        // Circular hand pour motion translation offsets
                        let kettleOffsetX = isRunning ? cos(time * speedMult) * ampX : 0.0
                        let kettleOffsetY = isRunning ? sin(time * speedMult) * ampY : 0.0
                        let kettleRotation = isRunning ? -22.0 + sin(time * speedMult) * rotAmp : -22.0
                        
                        // 1. DRAW KETTLE (tilted & moving in circular motion if running)
                        var kettleCtx = scaledCtx
                        kettleCtx.translateBy(x: 135 + kettleOffsetX, y: 55 + kettleOffsetY)
                        kettleCtx.rotate(by: .degrees(kettleRotation))
                        kettleCtx.scaleBy(x: 0.8, y: 0.8)
                        
                        // Kettle Body: tapered profile
                        var bodyPath = Path()
                        bodyPath.move(to: CGPoint(x: -14, y: -22)) // top-left
                        bodyPath.addLine(to: CGPoint(x: 14, y: -22)) // top-right
                        bodyPath.addLine(to: CGPoint(x: 24, y: 22)) // bottom-right
                        bodyPath.addQuadCurve(to: CGPoint(x: -24, y: 22), control: CGPoint(x: 0, y: 27))
                        bodyPath.closeSubpath()
                        kettleCtx.stroke(bodyPath, with: goldGradient, lineWidth: 2.5)
                        
                        // Lid
                        var lidPath = Path()
                        lidPath.move(to: CGPoint(x: -14, y: -22))
                        lidPath.addQuadCurve(to: CGPoint(x: 14, y: -22), control: CGPoint(x: 0, y: -27))
                        kettleCtx.stroke(lidPath, with: goldGradient, lineWidth: 2.5)
                        
                        // Knob on Lid
                        var knobPath = Path()
                        knobPath.move(to: CGPoint(x: -4, y: -27))
                        knobPath.addLine(to: CGPoint(x: 4, y: -27))
                        knobPath.addLine(to: CGPoint(x: 6, y: -32))
                        knobPath.addLine(to: CGPoint(x: -6, y: -32))
                        knobPath.closeSubpath()
                        kettleCtx.stroke(knobPath, with: goldGradient, lineWidth: 2.2)
                        
                        // Gooseneck Spout (double-lined for thickness)
                        var spoutOuter = Path()
                        spoutOuter.move(to: CGPoint(x: -20, y: 15))
                        spoutOuter.addCurve(
                            to: CGPoint(x: -48, y: -16),
                            control1: CGPoint(x: -38, y: 22),
                            control2: CGPoint(x: -52, y: 6)
                        )
                        spoutOuter.addQuadCurve(to: CGPoint(x: -52, y: -13), control: CGPoint(x: -51, y: -16))
                        
                        var spoutInner = Path()
                        spoutInner.move(to: CGPoint(x: -18, y: 7))
                        spoutInner.addCurve(
                            to: CGPoint(x: -44, y: -12),
                            control1: CGPoint(x: -32, y: 13),
                            control2: CGPoint(x: -46, y: 3)
                        )
                        spoutInner.addQuadCurve(to: CGPoint(x: -48, y: -10), control: CGPoint(x: -47, y: -12))
                        
                        kettleCtx.stroke(spoutOuter, with: goldGradient, lineWidth: 2.2)
                        kettleCtx.stroke(spoutInner, with: goldGradient, lineWidth: 2.2)
                        
                        var spoutTip = Path()
                        spoutTip.move(to: CGPoint(x: -52, y: -13))
                        spoutTip.addLine(to: CGPoint(x: -48, y: -10))
                        kettleCtx.stroke(spoutTip, with: goldGradient, lineWidth: 2.2)
                        
                        // Handle (looping on the right)
                        var handlePath = Path()
                        handlePath.move(to: CGPoint(x: 14, y: -17))
                        handlePath.addCurve(
                            to: CGPoint(x: 22, y: 15),
                            control1: CGPoint(x: 35, y: -22),
                            control2: CGPoint(x: 35, y: 8)
                        )
                        var handleInnerPath = Path()
                        handleInnerPath.move(to: CGPoint(x: 16, y: -12))
                        handleInnerPath.addCurve(
                            to: CGPoint(x: 23, y: 10),
                            control1: CGPoint(x: 31, y: -16),
                            control2: CGPoint(x: 31, y: 5)
                        )
                        kettleCtx.stroke(handlePath, with: goldGradient, lineWidth: 2.2)
                        kettleCtx.stroke(handleInnerPath, with: goldGradient, lineWidth: 2.2)
                        
                        // 2. DRAW VESSEL (Cup for V60, Chemex for Chemex)
                        if viewModel.method == .chemex {
                            let centerX = baseSize / 2
                            let beakerTop: CGFloat = 85
                            
                            // Draw Chemex Outline Silhouette (Wider & more elegant)
                            var chemexPath = Path()
                            chemexPath.move(to: CGPoint(x: centerX - 32, y: beakerTop + 8))
                            chemexPath.addLine(to: CGPoint(x: centerX + 32, y: beakerTop + 8))
                            chemexPath.addLine(to: CGPoint(x: centerX + 12, y: beakerTop + 38))
                            chemexPath.addLine(to: CGPoint(x: centerX + 38, y: beakerTop + 75))
                            chemexPath.addLine(to: CGPoint(x: centerX - 38, y: beakerTop + 75))
                            chemexPath.addLine(to: CGPoint(x: centerX - 12, y: beakerTop + 38))
                            chemexPath.closeSubpath()
                            
                            // Wooden collar band
                            var collarPath = Path()
                            collarPath.addRect(CGRect(x: centerX - 15, y: beakerTop + 33, width: 30, height: 10))
                            
                            // Draw Coffee Fill rising in Chemex bottom chamber based on progress
                            if progress > 0 {
                                var clippedCtx = scaledCtx
                                clippedCtx.clip(to: chemexPath)
                                
                                // Bottom chamber Y is from (beakerTop + 38) to (beakerTop + 75)
                                let bottomBeakerHeight = 37.0
                                let fillHeight = bottomBeakerHeight * progress
                                let fillY = (beakerTop + 75.0) - fillHeight
                                
                                var fillPath = Path()
                                fillPath.move(to: CGPoint(x: centerX - 45, y: beakerTop + 80))
                                fillPath.addLine(to: CGPoint(x: centerX - 45, y: fillY))
                                
                                // Wave top surface
                                for x in Int(centerX - 45)...Int(centerX + 45) {
                                    let wave = sin(Double(x) * 0.25 + time * 6.0) * 1.0
                                    fillPath.addLine(to: CGPoint(x: CGFloat(x), y: fillY + CGFloat(wave)))
                                }
                                
                                fillPath.addLine(to: CGPoint(x: centerX + 45, y: fillY))
                                fillPath.addLine(to: CGPoint(x: centerX + 45, y: beakerTop + 80))
                                fillPath.closeSubpath()
                                
                                let fillGradient = GraphicsContext.Shading.linearGradient(
                                    Gradient(colors: [Color.primaryCopper.opacity(0.45), Color.brushedCopper.opacity(0.15)]),
                                    startPoint: CGPoint(x: centerX, y: fillY),
                                    endPoint: CGPoint(x: centerX, y: beakerTop + 75)
                                )
                                clippedCtx.fill(fillPath, with: fillGradient)
                            }
                            
                            scaledCtx.stroke(chemexPath, with: goldGradient, lineWidth: 2.5)
                            scaledCtx.stroke(collarPath, with: goldGradient, lineWidth: 1.0)
                        } else {
                            // DRAW CUP (bottom center)
                            var cupCtx = scaledCtx
                            cupCtx.translateBy(x: 100, y: 155)
                            cupCtx.scaleBy(x: 0.9, y: 0.9)
                            
                            // Cup Rim (ellipse showing perspective)
                            let rimRect = CGRect(x: -30, y: -20, width: 60, height: 10)
                            var rimPath = Path()
                            rimPath.addEllipse(in: rimRect)
                            cupCtx.stroke(rimPath, with: goldGradient, lineWidth: 2.2)
                            
                            // Cup Body Path
                            var cupBody = Path()
                            cupBody.move(to: CGPoint(x: -30, y: -15))
                            cupBody.addCurve(
                                to: CGPoint(x: -16, y: 20),
                                control1: CGPoint(x: -28, y: 5),
                                control2: CGPoint(x: -22, y: 18)
                            )
                            cupBody.addLine(to: CGPoint(x: 16, y: 20))
                            cupBody.addCurve(
                                to: CGPoint(x: 30, y: -15),
                                control1: CGPoint(x: 22, y: 18),
                                control2: CGPoint(x: 28, y: 5)
                            )
                            cupBody.closeSubpath()
                            cupCtx.stroke(cupBody, with: goldGradient, lineWidth: 2.5)
                            
                            // Cup Base Ring
                            var cupBase = Path()
                            cupBase.addEllipse(in: CGRect(x: -16, y: 17, width: 32, height: 6))
                            cupCtx.stroke(cupBase, with: goldGradient, lineWidth: 2.2)
                            
                            // Handle on the right
                            var cupHandle = Path()
                            cupHandle.move(to: CGPoint(x: 28, y: -10))
                            cupHandle.addCurve(
                                to: CGPoint(x: 20, y: 15),
                                control1: CGPoint(x: 44, y: -8),
                                control2: CGPoint(x: 42, y: 12)
                            )
                            var cupHandleInner = Path()
                            cupHandleInner.move(to: CGPoint(x: 28, y: -5))
                            cupHandleInner.addCurve(
                                to: CGPoint(x: 21, y: 10),
                                control1: CGPoint(x: 38, y: -4),
                                control2: CGPoint(x: 36, y: 8)
                            )
                            cupCtx.stroke(cupHandle, with: goldGradient, lineWidth: 2.2)
                            cupCtx.stroke(cupHandleInner, with: goldGradient, lineWidth: 2.2)
                            
                            // Coffee Fill inside the cup (clipping to the cup body walls to look completely full)
                            if progress > 0 {
                                var clippedCtx = cupCtx
                                clippedCtx.clip(to: cupBody)
                                
                                // Total height is 35 points (from Y=20 base to Y=-15 rim)
                                let fillHeight = 35.0 * progress
                                let fillY = 20.0 - fillHeight
                                
                                var fillPath = Path()
                                fillPath.move(to: CGPoint(x: -35.0, y: 25.0)) // bottom-left (beyond walls)
                                fillPath.addLine(to: CGPoint(x: -35.0, y: fillY))
                                
                                // Wave top surface
                                for x in -35...35 {
                                    let wave = sin(Double(x) * 0.25 + time * 8.0) * 1.5
                                    fillPath.addLine(to: CGPoint(x: CGFloat(x), y: fillY + CGFloat(wave)))
                                }
                                
                                fillPath.addLine(to: CGPoint(x: 35.0, y: fillY))
                                fillPath.addLine(to: CGPoint(x: 35.0, y: 25.0)) // bottom-right
                                fillPath.closeSubpath()
                                
                                let fillGradient = GraphicsContext.Shading.linearGradient(
                                    Gradient(colors: [Color.primaryCopper.opacity(0.45), Color.brushedCopper.opacity(0.15)]),
                                    startPoint: CGPoint(x: 0, y: fillY),
                                    endPoint: CGPoint(x: 0, y: 20)
                                )
                                clippedCtx.fill(fillPath, with: fillGradient)
                            }
                        }
                        
                        // 3. DRAW CONSTELLATION FLOW (Only when running)
                        let showStream = isRunning || (viewModel.elapsed > 0 && viewModel.elapsed < viewModel.totalDuration)
                        
                        if showStream {
                            let animTime = isRunning ? time : (time * 0.05) // slow crawl on pause
                            let overallOpacity = isRunning ? 1.0 : 0.20 // softened dim stream on pause
                            
                            let p0 = CGPoint(x: 94.0 + kettleOffsetX, y: 61.0 + kettleOffsetY)
                            let p1 = CGPoint(x: 45.0 + kettleOffsetX * 0.5, y: 85.0 + kettleOffsetY * 0.5)
                            let p2 = CGPoint(x: 155.0, y: 115.0)
                            let p3: CGPoint
                            if viewModel.method == .chemex {
                                p3 = CGPoint(x: 100.0, y: 95.0)
                            } else {
                                p3 = CGPoint(x: 100.0, y: 137.0)
                            }
                            
                            func bezierPoint(t: Double, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
                                let mt = 1.0 - t
                                let mt2 = mt * mt
                                let mt3 = mt2 * mt
                                let t2 = t * t
                                let t3 = t2 * t
                                return CGPoint(
                                    x: mt3 * p0.x + 3.0 * mt2 * t * p1.x + 3.0 * mt * t2 * p2.x + t3 * p3.x,
                                    y: mt3 * p0.y + 3.0 * mt2 * t * p1.y + 3.0 * mt * t2 * p2.y + t3 * p3.y
                                )
                            }
                            
                            // 1. Tighter stream: lower particle count (28 -> 18) for elegancy
                            let particleCount = 18
                            var points: [CGPoint] = []
                            let flowSpeed = viewModel.method == .chemex ? 0.12 : 0.22
                            let isBloom = viewModel.getPhaseText().localizedCaseInsensitiveContains("bloom")
                            
                            for i in 0..<particleCount {
                                let offset = Double(i) / Double(particleCount)
                                let p = (offset + animTime * flowSpeed).truncatingRemainder(dividingBy: 1.0)
                                let basePt = bezierPoint(t: p, p0: p0, p1: p1, p2: p2, p3: p3)
                                
                                // 2. Tighter stream: smaller spiral radius (15.0 -> 4.0)
                                let angle = p * 14.0 * .pi + animTime * 5.0 + Double(i) * 0.9
                                let radius = sin(p * .pi) * 4.0 + 0.5
                                let dx = cos(angle) * radius
                                let dy = sin(angle) * radius * 0.35
                                
                                points.append(CGPoint(x: basePt.x + dx, y: basePt.y + dy))
                            }
                            
                            // Draw thin connecting wireframe lines with soft fade near the bottom
                            for i in 0..<particleCount {
                                for j in (i + 1)..<particleCount {
                                    let pi = points[i]
                                    let pj = points[j]
                                    let dx = pi.x - pj.x
                                    let dy = pi.y - pj.y
                                    let dist = sqrt(dx*dx + dy*dy)
                                    
                                    if dist < 18.0 {
                                        // Calculate progress p for the line
                                        let p = Double(i) / Double(particleCount)
                                        let bloomScale = isBloom ? max(0.0, 1.0 - p * 2.2) : 1.0
                                        let lineOpacity = (17.0 - dist) / 17.0 * 0.45 * (1.0 - pow(p, 3.0)) * bloomScale * overallOpacity
                                        
                                        if lineOpacity > 0.01 {
                                            var linePath = Path()
                                            linePath.move(to: pi)
                                            linePath.addLine(to: pj)
                                            scaledCtx.stroke(linePath, with: .color(Color.primaryCopper.opacity(lineOpacity)), lineWidth: 0.8)
                                        }
                                    }
                                }
                            }
                            
                            // Draw spheres with metallic specular highlight and tapering sizes + fades
                            for i in 0..<particleCount {
                                let pt = points[i]
                                let p = (Double(i) / Double(particleCount) + animTime * flowSpeed).truncatingRemainder(dividingBy: 1.0)
                                
                                // 3. Tapering size: droplets get smaller down the stream
                                let scaleFactor = 1.0 - (p * 0.6) // tapers from 100% to 40% at bottom
                                let r: CGFloat = (1.6 + CGFloat(sin(p * .pi) * 1.0)) * CGFloat(scaleFactor)
                                
                                // Bloom & Pause opacity fades
                                let bloomScale = isBloom ? max(0.0, 1.0 - p * 2.2) : 1.0
                                let opacity = (1.0 - pow(p, 3.0)) * bloomScale * overallOpacity
                                
                                if opacity > 0.01 {
                                    var spherePath = Path()
                                    spherePath.addArc(
                                        center: pt,
                                        radius: r,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360),
                                        clockwise: false
                                    )
                                    
                                    var particleCtx = scaledCtx
                                    particleCtx.opacity = opacity
                                    particleCtx.fill(spherePath, with: goldGradient)
                                    
                                    var highlightPath = Path()
                                    highlightPath.addArc(
                                        center: CGPoint(x: pt.x - r * 0.3, y: pt.y - r * 0.3),
                                        radius: r * 0.3,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360),
                                        clockwise: false
                                    )
                                    particleCtx.fill(highlightPath, with: .color(.white.opacity(0.8)))
                                }
                            }
                        }
                    } else {
                        // French Press or Aeropress Plunger Animation
                        var scaledCtx = ctx
                        let isRunning = viewModel.isRunning
                        scaledCtx.translateBy(
                            x: (size.width - (baseSize * scale)) / 2,
                            y: (size.height - (baseSize * scale)) / 2
                        )
                        scaledCtx.scaleBy(x: scale, y: scale)
                        
                        let w: CGFloat = 200
                        
                        let beakerW: CGFloat = 68
                        let centerX = w / 2
                        let beakerLeft = centerX - beakerW / 2
                        let beakerRight = centerX + beakerW / 2
                        let beakerTop: CGFloat = 85
                        let beakerBottom: CGFloat = 185
                        
                        let goldGradient = GraphicsContext.Shading.linearGradient(
                            Gradient(colors: [Color.primaryCopper, Color.brushedCopper]),
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: 200, y: 200)
                        )
                        
                        if viewModel.method == .aeropress {
                            // 1. ANIMATION PROGRESS
                            let fpSteepDuration: TimeInterval = viewModel.customSteepDuration ?? (viewModel.method == .aeropress ? 60.0 : 240.0)
                            let fpPlungeDuration: TimeInterval = viewModel.customPressDuration ?? (viewModel.method == .aeropress ? 30.0 : 15.0)
                            
                            let pressProgress: Double = {
                                if viewModel.elapsed < fpSteepDuration {
                                    return 0.0
                                } else {
                                    return min((viewModel.elapsed - fpSteepDuration) / fpPlungeDuration, 1.0)
                                }
                            }()
                            
                            let chamberTop: CGFloat = 80
                            let chamberBottom: CGFloat = 145
                            let chamberW: CGFloat = 40
                            let chamberLeft = centerX - chamberW / 2
                            let chamberRight = centerX + chamberW / 2
                            
                            // Plunger seal position descends from chamberTop + 5 to chamberBottom - 6
                            let plungerY = chamberTop + 5.0 + (chamberBottom - 6.0 - (chamberTop + 5.0)) * CGFloat(pressProgress)
                            
                            // 2. LIQUID FILLS
                            // Coffee inside the chamber (shrinks as plunger descends)
                            if plungerY < chamberBottom {
                                var chamberCoffeePath = Path()
                                chamberCoffeePath.addRect(CGRect(x: chamberLeft + 1.5, y: plungerY, width: chamberW - 3.0, height: chamberBottom - plungerY))
                                
                                // Subtle wave animation during steep phase
                                let coffeeFillColor = Color(red: 0.18, green: 0.12, blue: 0.08).opacity(0.68)
                                scaledCtx.fill(chamberCoffeePath, with: .color(coffeeFillColor))
                            }
                            
                            // Coffee rising inside the receiving cup below
                            let cupRimY: CGFloat = 168
                            let cupBottomY: CGFloat = 193
                            let cupW: CGFloat = 44
                            let cupLeft = centerX - cupW / 2
                            let cupRight = centerX + cupW / 2
                            
                            if pressProgress > 0 {
                                let cupFillHeight = (cupBottomY - cupRimY - 4.0) * CGFloat(pressProgress)
                                let cupFillY = cupBottomY - cupFillHeight
                                var cupCoffeePath = Path()
                                cupCoffeePath.addRect(CGRect(x: cupLeft + 2.0, y: cupFillY, width: cupW - 4.0, height: cupFillHeight))
                                scaledCtx.fill(cupCoffeePath, with: .color(Color(red: 0.28, green: 0.18, blue: 0.12).opacity(0.55)))
                            }
                            
                            // 3. MECHANICAL PLUNGER DESCENT
                            // Plunger Inner Body (hollow core)
                            var plungerBody = Path()
                            plungerBody.addRect(CGRect(x: centerX - 16, y: plungerY - 50, width: 32, height: 50))
                            scaledCtx.stroke(plungerBody, with: goldGradient, lineWidth: 1.2)
                            
                            // Plunger Top Flange / Button
                            var plungerFlange = Path()
                            plungerFlange.addRect(CGRect(x: centerX - 22, y: plungerY - 55, width: 44, height: 5))
                            scaledCtx.fill(plungerFlange, with: goldGradient)
                            
                            // Plunger Rubber Seal (black/dark copper line at the bottom of the plunger)
                            var plungerSeal = Path()
                            plungerSeal.addRect(CGRect(x: chamberLeft + 1.0, y: plungerY - 3.0, width: chamberW - 2.0, height: 6.0))
                            scaledCtx.fill(plungerSeal, with: .color(Color.primaryCopper))
                            
                            // 4. OUTER CHAMBER SILHOUETTE
                            var chamberPath = Path()
                            // Left and Right walls
                            chamberPath.move(to: CGPoint(x: chamberLeft, y: chamberTop))
                            chamberPath.addLine(to: CGPoint(x: chamberLeft, y: chamberBottom))
                            chamberPath.move(to: CGPoint(x: chamberRight, y: chamberTop))
                            chamberPath.addLine(to: CGPoint(x: chamberRight, y: chamberBottom))
                            // Top lip flange
                            chamberPath.move(to: CGPoint(x: chamberLeft - 6, y: chamberTop))
                            chamberPath.addLine(to: CGPoint(x: chamberRight + 6, y: chamberTop))
                            
                            scaledCtx.stroke(chamberPath, with: .color(strokeColor.opacity(0.35)), lineWidth: 2.5)
                            
                            // Filter Cap at bottom (black grid attachment)
                            var filterCap = Path()
                            filterCap.addRect(CGRect(x: centerX - 22, y: chamberBottom, width: 44, height: 8))
                            scaledCtx.fill(filterCap, with: .color(Color.primaryCopper.opacity(0.35)))
                            scaledCtx.stroke(filterCap, with: goldGradient, lineWidth: 1.2)
                            
                            // 5. HIGH-PRESSURE OUTPUT STREAM (During Press)
                            let isPressing = viewModel.elapsed >= fpSteepDuration && viewModel.elapsed < (fpSteepDuration + fpPlungeDuration)
                            if isPressing && isRunning {
                                // Dynamic thin drop lines from filter cap to cup
                                var streamPath = Path()
                                for offset in [-6.0, 0.0, 6.0] {
                                    // Add minor noise oscillation
                                    let drift = sin(time * 25.0 + offset) * 0.8
                                    streamPath.move(to: CGPoint(x: centerX + offset + drift, y: chamberBottom + 8))
                                    streamPath.addLine(to: CGPoint(x: centerX + offset + drift, y: cupRimY))
                                }
                                scaledCtx.stroke(streamPath, with: .color(Color.primaryCopper.opacity(0.75)), lineWidth: 1.2)
                            }
                            
                            // 6. RECEIVING MUG/CUP BELOW
                            var cupPath = Path()
                            // Cup rim ellipse
                            cupPath.addEllipse(in: CGRect(x: cupLeft, y: cupRimY - 4.0, width: cupW, height: 8.0))
                            // Cup body walls
                            cupPath.move(to: CGPoint(x: cupLeft, y: cupRimY))
                            cupPath.addLine(to: CGPoint(x: cupLeft, y: cupBottomY))
                            cupPath.addLine(to: CGPoint(x: cupRight, y: cupBottomY))
                            cupPath.addLine(to: CGPoint(x: cupRight, y: cupRimY))
                            
                            scaledCtx.stroke(cupPath, with: .color(strokeColor.opacity(0.35)), lineWidth: 2.5)
                            
                            // Mug handle on the right
                            var cupHandle = Path()
                            cupHandle.move(to: CGPoint(x: cupRight, y: cupRimY + 5.0))
                            cupHandle.addCurve(to: CGPoint(x: cupRight, y: cupBottomY - 5.0),
                                               control1: CGPoint(x: cupRight + 12, y: cupRimY + 3.0),
                                               control2: CGPoint(x: cupRight + 12, y: cupBottomY - 3.0))
                            scaledCtx.stroke(cupHandle, with: goldGradient, lineWidth: 2.2)
                        } else {
                            // French Press Plunger Animation
                            
                            let fpSteepDuration: TimeInterval = viewModel.customSteepDuration ?? (viewModel.method == .frenchPress ? 240.0 : 60.0)
                            let fpPlungeDuration: TimeInterval = viewModel.customPressDuration ?? (viewModel.method == .frenchPress ? 15.0 : 30.0)
                            let steepProgress: Double = {
                                if viewModel.elapsed < fpSteepDuration {
                                    return 0.0
                                } else {
                                    return min((viewModel.elapsed - fpSteepDuration) / fpPlungeDuration, 1.0)
                                }
                            }()
                            
                            let filterStart = beakerTop + 15
                            let filterEnd = beakerBottom - 23
                            let filterY = filterStart + (filterEnd - filterStart) * CGFloat(steepProgress)
                            
                            let knobStart = beakerTop - 40
                            let knobEnd = beakerTop - 9
                            let knobY = knobStart + (knobEnd - knobStart) * CGFloat(steepProgress)
                            
                            // 1. BEAKER LIQUID FILLS (Immersion and Filtration)
                            // Clean amber coffee above the plunging filter
                            if filterY > beakerTop + 15 {
                                var cleanCoffeePath = Path()
                                cleanCoffeePath.addRect(CGRect(x: beakerLeft + 2, y: beakerTop + 15, width: beakerW - 4, height: filterY - (beakerTop + 15)))
                                scaledCtx.fill(cleanCoffeePath, with: .color(Color(red: 0.28, green: 0.18, blue: 0.12).opacity(0.35)))
                            }
                            
                            // Dark immersion coffee below the filter
                            if filterY < beakerBottom - 2 {
                                var darkCoffeePath = Path()
                                darkCoffeePath.addRect(CGRect(x: beakerLeft + 2, y: filterY, width: beakerW - 4, height: beakerBottom - 2 - filterY))
                                scaledCtx.fill(darkCoffeePath, with: .color(Color(red: 0.18, green: 0.12, blue: 0.08).opacity(0.68)))
                            }
                            
                            // Sediment layer at the bottom: grows taller/denser as plunge completes
                            let sedimentOpacity = 0.4 + (steepProgress * 0.5) // from 0.4 to 0.9
                            let sedimentHeight = 6.0 + (steepProgress * 16.0) // grows from 6pt to 22pt as grounds compress
                            var groundsBgPath = Path()
                            groundsBgPath.addRect(CGRect(x: beakerLeft + 2, y: beakerBottom - sedimentHeight, width: beakerW - 4, height: sedimentHeight))
                            scaledCtx.fill(groundsBgPath, with: .color(Color(red: 0.16, green: 0.11, blue: 0.08).opacity(sedimentOpacity)))
                            
                            // 2. DETAILED IMMERSION COFFEE GROUNDS (Stippling)
                            // During steep, grounds float throughout. During plunge, they are pushed down below filterY.
                            let dotsCount = 90
                            for i in 0..<dotsCount {
                                // Deterministic natural floating height (spread across beakerTop + 18 to beakerBottom - 25)
                                let floatRatio = Double((i * 17) % 100) / 100.0
                                let floatY = (beakerTop + 18) + CGFloat(floatRatio) * (beakerBottom - 25 - (beakerTop + 18))
                                
                                // Drift oscillation during steep to look like suspended immersion grounds
                                let driftSpeed = isRunning ? 1.0 : 0.05
                                let driftX = sin(time * driftSpeed * 0.8 + Double(i)) * 1.5
                                let driftY = cos(time * driftSpeed * 0.6 + Double(i)) * 1.0
                                
                                let dotX = beakerLeft + 3.5 + CGFloat((i * 29) % Int(beakerW - 7)) + driftX
                                
                                // Plunger pushes grounds down: clamp ground Y to sit under filterY
                                let activeY = max(floatY + driftY, filterY + 3.0)
                                let clampedY = min(activeY, beakerBottom - 5.0)
                                
                                // Grounds diameter (larger at the very bottom, smaller floating)
                                let isNearBottom = clampedY > beakerBottom - 25
                                let r: CGFloat = isNearBottom ? (1.0 + Double((i * 7) % 3) * 0.3) : (0.5 + Double((i * 3) % 3) * 0.15)
                                
                                var dotPath = Path()
                                dotPath.addArc(center: CGPoint(x: dotX, y: clampedY), radius: r, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                                scaledCtx.fill(dotPath, with: goldGradient)
                            }
                            
                            // 3. BOROSILICATE GLASS BEAKER
                            var beakerPath = Path()
                            beakerPath.move(to: CGPoint(x: beakerLeft - 5, y: beakerTop - 2)) // Spout lip
                            beakerPath.addQuadCurve(to: CGPoint(x: beakerLeft, y: beakerTop + 2), control: CGPoint(x: beakerLeft - 2, y: beakerTop + 2))
                            beakerPath.addLine(to: CGPoint(x: beakerLeft, y: beakerBottom)) // Left wall
                            beakerPath.addLine(to: CGPoint(x: beakerRight, y: beakerBottom)) // Bottom wall
                            beakerPath.addLine(to: CGPoint(x: beakerRight, y: beakerTop)) // Right wall
                            scaledCtx.stroke(beakerPath, with: .color(strokeColor.opacity(0.35)), lineWidth: 2.5)
                            
                            // 4. METAL SUPPORT FRAME & ERGONOMIC HANDLE
                            var baseFrame = Path()
                            baseFrame.move(to: CGPoint(x: beakerLeft - 2, y: beakerBottom))
                            baseFrame.addLine(to: CGPoint(x: beakerLeft - 2, y: beakerBottom + 3))
                            baseFrame.addLine(to: CGPoint(x: beakerRight + 2, y: beakerBottom + 3))
                            baseFrame.addLine(to: CGPoint(x: beakerRight + 2, y: beakerBottom))
                            
                            // Left Foot
                            baseFrame.move(to: CGPoint(x: beakerLeft + 4, y: beakerBottom + 3))
                            baseFrame.addLine(to: CGPoint(x: beakerLeft + 2, y: beakerBottom + 7))
                            baseFrame.addLine(to: CGPoint(x: beakerLeft + 12, y: beakerBottom + 7))
                            baseFrame.addLine(to: CGPoint(x: beakerLeft + 14, y: beakerBottom + 3))
                            
                            // Right Foot
                            baseFrame.move(to: CGPoint(x: beakerRight - 14, y: beakerBottom + 3))
                            baseFrame.addLine(to: CGPoint(x: beakerRight - 12, y: beakerBottom + 7))
                            baseFrame.addLine(to: CGPoint(x: beakerRight - 2, y: beakerBottom + 7))
                            baseFrame.addLine(to: CGPoint(x: beakerRight - 4, y: beakerBottom + 3))
                            
                            // Horizontal Bands
                            baseFrame.move(to: CGPoint(x: beakerLeft - 1, y: beakerTop + 15))
                            baseFrame.addLine(to: CGPoint(x: beakerRight + 1, y: beakerTop + 15))
                            baseFrame.move(to: CGPoint(x: beakerLeft - 1, y: beakerBottom - 35))
                            baseFrame.addLine(to: CGPoint(x: beakerRight + 1, y: beakerBottom - 35))
                            
                            // Vertical Bands
                            baseFrame.move(to: CGPoint(x: beakerLeft + 8, y: beakerTop + 2))
                            baseFrame.addLine(to: CGPoint(x: beakerLeft + 8, y: beakerBottom))
                            baseFrame.move(to: CGPoint(x: beakerRight - 8, y: beakerTop + 2))
                            baseFrame.addLine(to: CGPoint(x: beakerRight - 8, y: beakerBottom))
                            
                            scaledCtx.stroke(baseFrame, with: goldGradient, lineWidth: 2.2)
                            
                            // Curved Handle
                            var handlePath = Path()
                            handlePath.move(to: CGPoint(x: beakerRight - 1, y: beakerTop + 15))
                            handlePath.addCurve(to: CGPoint(x: beakerRight - 1, y: beakerBottom - 35),
                                                control1: CGPoint(x: beakerRight + 24, y: beakerTop + 10),
                                                control2: CGPoint(x: beakerRight + 24, y: beakerBottom - 30))
                            scaledCtx.stroke(handlePath, with: goldGradient, lineWidth: 2.5)
                            
                            // 5. LID DOME
                            var lidPath = Path()
                            lidPath.move(to: CGPoint(x: beakerLeft - 2, y: beakerTop))
                            lidPath.addLine(to: CGPoint(x: beakerRight + 2, y: beakerTop))
                            lidPath.addLine(to: CGPoint(x: beakerRight + 2, y: beakerTop - 4))
                            lidPath.addQuadCurve(to: CGPoint(x: beakerLeft - 2, y: beakerTop - 4), control: CGPoint(x: centerX, y: beakerTop - 15))
                            lidPath.closeSubpath()
                            
                            scaledCtx.fill(lidPath, with: .color(Color.primaryCopper.opacity(0.12)))
                            scaledCtx.stroke(lidPath, with: goldGradient, lineWidth: 2.2)
                            
                            // Silicone seal band
                            var sealPath = Path()
                            sealPath.move(to: CGPoint(x: beakerLeft - 1, y: beakerTop))
                            sealPath.addLine(to: CGPoint(x: beakerRight + 1, y: beakerTop))
                            scaledCtx.stroke(sealPath, with: .color(strokeColor.opacity(0.65)), lineWidth: 2.2)
                            
                            // 6. DYNAMIC PLUNGER SHAFT, KNOB & FILTER PLATE
                            // Plunger Shaft
                            var shaftPath = Path()
                            shaftPath.move(to: CGPoint(x: centerX, y: knobY + 5))
                            shaftPath.addLine(to: CGPoint(x: centerX, y: filterY))
                            scaledCtx.stroke(shaftPath, with: goldGradient, lineWidth: 2.2)
                            
                            // Plunger Knob (sphere)
                            var knobPath = Path()
                            knobPath.addArc(center: CGPoint(x: centerX, y: knobY), radius: 5.0, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                            scaledCtx.fill(knobPath, with: goldGradient)
                            
                            // Knob specular highlights
                            var knobHighlight = Path()
                            knobHighlight.addArc(center: CGPoint(x: centerX - 1.5, y: knobY - 1.5), radius: 1.5, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                            scaledCtx.fill(knobHighlight, with: .color(.white.opacity(0.8)))
                            
                            // Filter Plate (mesh)
                            var filterPlate = Path()
                            filterPlate.move(to: CGPoint(x: beakerLeft + 2.5, y: filterY))
                            filterPlate.addLine(to: CGPoint(x: beakerRight - 2.5, y: filterY))
                            scaledCtx.stroke(filterPlate, with: goldGradient, lineWidth: 2.2)
                            
                            // Coarse mesh layers
                            var filterMesh = Path()
                            filterMesh.move(to: CGPoint(x: beakerLeft + 4.5, y: filterY + 2.5))
                            filterMesh.addLine(to: CGPoint(x: beakerRight - 4.5, y: filterY + 2.5))
                            scaledCtx.stroke(filterMesh, with: goldGradient, lineWidth: 1.0)
                        }
                    }
                }
                .frame(width: 228, height: 228)
            }
            .frame(width: 288, height: 288)
        }
    }
}
