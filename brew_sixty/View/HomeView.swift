import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var activeIndex: Int = 0
    @State private var isZoomedOut = false
    
    // ViewModels for V60 and French Press recipe cards
    @State private var v60ViewModel = HomeBrewViewModel(method: .v60, beanWeight: 15.0, ratio: 16.5, waterVolume: 250.0)
    @State private var pressViewModel = HomeBrewViewModel(method: .frenchPress, beanWeight: 18.0, ratio: 15.0, waterVolume: 300.0)
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 64
            let viewModels = [v60ViewModel, pressViewModel]
            let cardToTabBarSpacing: CGFloat = 30
            
            ZStack {
                // Solid dark charcoal background matching mock
                Color(red: 0.08, green: 0.08, blue: 0.08)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section matching the mock large serif title
                    Text("Hello Charu!")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    GeometryReader { cardProxy in
                        let cardHeight = max(cardProxy.size.height - cardToTabBarSpacing, 0)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: isZoomedOut ? 16 : 20) {
                                ForEach(0..<viewModels.count, id: \.self) { idx in
                                    let vm = viewModels[idx]
                                    LiveTimerCard(viewModel: vm, isZoomedOut: isZoomedOut, activeIndex: $activeIndex, myIndex: idx)
                                        .frame(width: cardWidth, height: cardHeight)
                                        .scaleEffect(isZoomedOut ? 0.85 : (activeIndex == idx ? 1.0 : 0.92))
                                        .id(idx)
                                        .onTapGesture {
                                            if isZoomedOut {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                    isZoomedOut = false
                                                    activeIndex = idx
                                                }
                                            }
                                        }
                                        .gesture(
                                            LongPressGesture(minimumDuration: 0.5)
                                                .onEnded { _ in
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                        isZoomedOut = true
                                                    }
                                                }
                                        )
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
                        .safeAreaPadding(.horizontal, isZoomedOut ? 48 : 32)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

@MainActor
struct LiveTimerCard: View {
    let viewModel: HomeBrewViewModel
    let isZoomedOut: Bool
    @Binding var activeIndex: Int
    let myIndex: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Inner Timer Card Container wrapping the timer circle, Kettle canvas animation, and overlay text
                VStack(spacing: 10) {
                    TimerCircleView(viewModel: viewModel)
                    
                    // Recipe info overlays
                    VStack(spacing: 6) {
                        Text(formatTime(viewModel.elapsed > 0 ? viewModel.elapsed : viewModel.totalDuration))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 8) {
                            Text(viewModel.method.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primaryCopper)
                            
                            Circle()
                                .fill(Color.white.opacity(0.22))
                                .frame(width: 4, height: 4)
                            
                            Text(viewModel.getPhaseText())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.10, green: 0.09, blue: 0.09))
                )
                .liquidGlassBorder(cornerRadius: 16)
                
                if !viewModel.isRunning && viewModel.elapsed == 0 {
                    HStack(spacing: 10) {
                        doseButton("8g")
                        doseButton("16g")
                        doseButton("24g")
                    }
                    .padding(.top, 2)
                    .transition(.opacity)
                }
                
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
                        Text(viewModel.isRunning ? "PAUSE BREW" : "START BREW")
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
                    HStack(spacing: 20) {
                        Button {
                            viewModel.resetTimer()
                        } label: {
                            Text("Reset")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.05), in: Capsule())
                                .liquidGlassBorder(cornerRadius: 20)
                        }
                        
                        Button {
                            viewModel.skipPhase()
                        } label: {
                            Text("Skip Phase")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.05), in: Capsule())
                                .liquidGlassBorder(cornerRadius: 20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding()
            .padding(.bottom, 12)
        }
        .premiumCardBackground(cornerRadius: 24)
        .liquidGlassBorder(cornerRadius: 24)
    }
    
    private func doseButton(_ label: String) -> some View {
        let doseNum = Double(label.replacingOccurrences(of: "g", with: "")) ?? 15.0
        let isSelected = abs(viewModel.beanWeight - doseNum) < 0.1
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                viewModel.beanWeight = doseNum
            }
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(colors: [Color.primaryCopper, Color.brushedCopper], startPoint: .topLeading, endPoint: .bottomTrailing)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(20)
                .overlay(
                    Group {
                        if !isSelected {
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                    }
                )
                .foregroundStyle(isSelected ? Color(red: 0.12, green: 0.08, blue: 0.08) : Color.white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
    
    private var phases: [BrewPhase] {
        switch viewModel.method {
        case .v60:
            [
                BrewPhase(title: "Bloom", description: "\(formatGrams(viewModel.bloomWater)) Water • Swirl gently", duration: "45s", icon: "stopwatch"),
                BrewPhase(title: "First Pour", description: "To \(formatGrams(viewModel.firstPourWater)) • Spiral motion", duration: "60s", icon: "drop"),
                BrewPhase(title: "Final Drawdown", description: "To \(formatGrams(viewModel.targetWater)) • Flat bed", duration: "Ready", icon: "hourglass")
            ]
        case .frenchPress:
            [
                BrewPhase(title: "Steep", description: "Pour \(formatGrams(viewModel.targetWater)) • Let it sit", duration: "240s", icon: "stopwatch"),
                BrewPhase(title: "Plunge", description: "Press down slowly", duration: "15s", icon: "hourglass")
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
                    .stroke(Color.white.opacity(0.04), lineWidth: 8)
                    .frame(width: 228, height: 228)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(colors: [Color.primaryCopper, Color.brushedCopper], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 228, height: 228)
                    .rotationEffect(.degrees(-90))
                
                // Canvas Animation for Kettle pouring or French Press Plunging
                Canvas { ctx, size in
                    let time = context.date.timeIntervalSince1970
                    let baseSize: CGFloat = 200
                    let scale = min(size.width, size.height) / baseSize * 0.96
                    let strokeColor = Color.coffeeCream.opacity(0.92)
                    let accentColor = Color.primaryCopper.opacity(0.95)
                    let fillColor = Color.brushedCopper.opacity(0.78)
                    let strokeWidth: CGFloat = 3
                    
                    if viewModel.method == .v60 {
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
                        
                        // Circular hand pour motion translation offsets
                        let kettleOffsetX = isRunning ? cos(time * 3.5) * 8.0 : 0.0
                        let kettleOffsetY = isRunning ? sin(time * 3.5) * 4.0 : 0.0
                        let kettleRotation = isRunning ? -22.0 + sin(time * 3.5) * 3.0 : -22.0
                        
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
                        kettleCtx.stroke(bodyPath, with: goldGradient, lineWidth: 2)
                        
                        // Lid
                        var lidPath = Path()
                        lidPath.move(to: CGPoint(x: -14, y: -22))
                        lidPath.addQuadCurve(to: CGPoint(x: 14, y: -22), control: CGPoint(x: 0, y: -27))
                        kettleCtx.stroke(lidPath, with: goldGradient, lineWidth: 2)
                        
                        // Knob on Lid
                        var knobPath = Path()
                        knobPath.move(to: CGPoint(x: -4, y: -27))
                        knobPath.addLine(to: CGPoint(x: 4, y: -27))
                        knobPath.addLine(to: CGPoint(x: 6, y: -32))
                        knobPath.addLine(to: CGPoint(x: -6, y: -32))
                        knobPath.closeSubpath()
                        kettleCtx.stroke(knobPath, with: goldGradient, lineWidth: 1.5)
                        
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
                        
                        kettleCtx.stroke(spoutOuter, with: goldGradient, lineWidth: 1.5)
                        kettleCtx.stroke(spoutInner, with: goldGradient, lineWidth: 1.5)
                        
                        var spoutTip = Path()
                        spoutTip.move(to: CGPoint(x: -52, y: -13))
                        spoutTip.addLine(to: CGPoint(x: -48, y: -10))
                        kettleCtx.stroke(spoutTip, with: goldGradient, lineWidth: 1.5)
                        
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
                        kettleCtx.stroke(handlePath, with: goldGradient, lineWidth: 1.5)
                        kettleCtx.stroke(handleInnerPath, with: goldGradient, lineWidth: 1.5)
                        
                        // 2. DRAW CUP (bottom center)
                        var cupCtx = scaledCtx
                        cupCtx.translateBy(x: 100, y: 155)
                        cupCtx.scaleBy(x: 0.9, y: 0.9)
                        
                        // Cup Rim (ellipse showing perspective)
                        let rimRect = CGRect(x: -30, y: -20, width: 60, height: 10)
                        var rimPath = Path()
                        rimPath.addEllipse(in: rimRect)
                        cupCtx.stroke(rimPath, with: goldGradient, lineWidth: 1.5)
                        
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
                        cupCtx.stroke(cupBody, with: goldGradient, lineWidth: 2)
                        
                        // Cup Base Ring
                        var cupBase = Path()
                        cupBase.addEllipse(in: CGRect(x: -16, y: 17, width: 32, height: 6))
                        cupCtx.stroke(cupBase, with: goldGradient, lineWidth: 1.5)
                        
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
                        cupCtx.stroke(cupHandle, with: goldGradient, lineWidth: 1.5)
                        cupCtx.stroke(cupHandleInner, with: goldGradient, lineWidth: 1.5)
                        
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
                        
                        // 3. DRAW CONSTELLATION FLOW (Only when running)
                        if isRunning {
                            let p0 = CGPoint(x: 94.0 + kettleOffsetX, y: 61.0 + kettleOffsetY)  // spout tip moves with kettle
                            let p1 = CGPoint(x: 45.0 + kettleOffsetX * 0.5, y: 85.0 + kettleOffsetY * 0.5) // waves trail
                            let p2 = CGPoint(x: 155.0, y: 115.0)
                            let p3 = CGPoint(x: 100.0, y: 137.0) // cup center rim
                            
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
                            
                            let particleCount = 28
                            var points: [CGPoint] = []
                            let flowSpeed = 0.22
                            
                            for i in 0..<particleCount {
                                let offset = Double(i) / Double(particleCount)
                                let p = (offset + time * flowSpeed).truncatingRemainder(dividingBy: 1.0)
                                let basePt = bezierPoint(t: p, p0: p0, p1: p1, p2: p2, p3: p3)
                                
                                // Spiral rotation and squashed y-axis for 3D illusion
                                let angle = p * 14.0 * .pi + time * 5.0 + Double(i) * 0.9
                                let radius = sin(p * .pi) * 15.0 + 1.0
                                let dx = cos(angle) * radius
                                let dy = sin(angle) * radius * 0.35
                                
                                points.append(CGPoint(x: basePt.x + dx, y: basePt.y + dy))
                            }
                            
                            // Draw thin connecting wireframe lines
                            for i in 0..<particleCount {
                                for j in (i + 1)..<particleCount {
                                    let pi = points[i]
                                    let pj = points[j]
                                    let dx = pi.x - pj.x
                                    let dy = pi.y - pj.y
                                    let dist = sqrt(dx*dx + dy*dy)
                                    
                                    if dist < 17.0 {
                                        var linePath = Path()
                                        linePath.move(to: pi)
                                        linePath.addLine(to: pj)
                                        
                                        let alpha = (17.0 - dist) / 17.0 * 0.45
                                        scaledCtx.stroke(linePath, with: .color(Color.primaryCopper.opacity(alpha)), lineWidth: 0.8)
                                    }
                                }
                            }
                            
                            // Draw spheres with metallic specular highlight
                            for i in 0..<particleCount {
                                let pt = points[i]
                                let p = (Double(i) / Double(particleCount) + time * flowSpeed).truncatingRemainder(dividingBy: 1.0)
                                let r: CGFloat = 2.0 + CGFloat(sin(p * .pi) * 1.5)
                                
                                var spherePath = Path()
                                spherePath.addArc(
                                    center: pt,
                                    radius: r,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360),
                                    clockwise: false
                                )
                                scaledCtx.fill(spherePath, with: goldGradient)
                                
                                var highlightPath = Path()
                                highlightPath.addArc(
                                    center: CGPoint(x: pt.x - r * 0.3, y: pt.y - r * 0.3),
                                    radius: r * 0.3,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360),
                                    clockwise: false
                                )
                                scaledCtx.fill(highlightPath, with: .color(.white.opacity(0.8)))
                            }
                        }
                    } else {
                        // French Press Plunger Animation
                        var scaledCtx = ctx
                        scaledCtx.translateBy(
                            x: (size.width - (baseSize * scale)) / 2,
                            y: (size.height - (baseSize * scale)) / 2
                        )
                        scaledCtx.scaleBy(x: scale, y: scale)
                        
                        let w: CGFloat = 200
                        let h: CGFloat = 200
                        
                        let beakerW: CGFloat = 68
                        let beakerH: CGFloat = 100
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
                        
                        let isRunning = viewModel.isRunning
                        
                        let fpSteepDuration: TimeInterval = 240.0
                        let fpPlungeDuration: TimeInterval = 15.0
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
                        
                        // 1. COARSE GROUND COFFEE (Layer at the bottom - Option B Stippled Sediment)
                        var groundsBgPath = Path()
                        groundsBgPath.addRect(CGRect(x: beakerLeft + 2.5, y: beakerBottom - 22, width: beakerW - 5, height: 21))
                        scaledCtx.fill(groundsBgPath, with: .color(Color(red: 0.16, green: 0.11, blue: 0.08).opacity(0.85)))
                        
                        // Crisp gold separator line on top of grounds
                        var separatorPath = Path()
                        separatorPath.move(to: CGPoint(x: beakerLeft + 2.5, y: beakerBottom - 22))
                        separatorPath.addLine(to: CGPoint(x: beakerRight - 2.5, y: beakerBottom - 22))
                        scaledCtx.stroke(separatorPath, with: goldGradient, lineWidth: 1.0)
                        
                        // Deterministic Gradated Stippling (90 dots)
                        for i in 0..<90 {
                            let randomX = beakerLeft + 3.5 + CGFloat((i * 29) % Int(beakerW - 7))
                            let randomY: CGFloat
                            let r: CGFloat
                            if i < 45 {
                                // Bottom layer (dense)
                                randomY = (beakerBottom - 7) - CGFloat((i * 13) % 7)
                                r = 1.0 + Double((i * 7) % 3) * 0.3 // 1.0 to 1.6
                            } else if i < 75 {
                                // Middle layer
                                randomY = (beakerBottom - 14) - CGFloat((i * 17) % 6)
                                r = 0.8 + Double((i * 11) % 3) * 0.2 // 0.8 to 1.2
                            } else {
                                // Top layer (sparse)
                                randomY = (beakerBottom - 21) - CGFloat((i * 19) % 6)
                                r = 0.5 + Double((i * 3) % 3) * 0.15 // 0.5 to 0.8
                            }
                            var dotPath = Path()
                            dotPath.addArc(center: CGPoint(x: randomX, y: randomY), radius: r, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                            scaledCtx.fill(dotPath, with: goldGradient)
                        }
                        
                        // 2. WATER FLOW VORTEX (3D helix swirl during steep phase, only when timer running)
                        if isRunning && viewModel.elapsed < fpSteepDuration {
                            let swirlTime = time * 4.0
                            for offset in [0.0, .pi] {
                                var swirlPath = Path()
                                for y in stride(from: CGFloat(beakerTop + 18), to: CGFloat(beakerBottom - 24), by: 1) {
                                    let t = (y - (beakerTop + 18)) / (beakerBottom - 24 - (beakerTop + 18))
                                    let amp = sin(t * .pi) * 8.0 // max amplitude in the middle is 8 points
                                    let angle = t * 3.0 * .pi - swirlTime + offset
                                    let x = centerX + sin(angle) * amp
                                    
                                    if y == beakerTop + 18 {
                                        swirlPath.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        swirlPath.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                                scaledCtx.stroke(swirlPath, with: .color(Color.primaryCopper.opacity(0.65)), lineWidth: 1.0)
                            }
                        }
                        
                        // 3. BOROSILICATE GLASS BEAKER
                        var beakerPath = Path()
                        beakerPath.move(to: CGPoint(x: beakerLeft - 5, y: beakerTop - 2)) // Spout lip
                        beakerPath.addQuadCurve(to: CGPoint(x: beakerLeft, y: beakerTop + 2), control: CGPoint(x: beakerLeft - 2, y: beakerTop + 2))
                        beakerPath.addLine(to: CGPoint(x: beakerLeft, y: beakerBottom)) // Left wall
                        beakerPath.addLine(to: CGPoint(x: beakerRight, y: beakerBottom)) // Bottom wall
                        beakerPath.addLine(to: CGPoint(x: beakerRight, y: beakerTop)) // Right wall
                        scaledCtx.stroke(beakerPath, with: .color(strokeColor.opacity(0.35)), lineWidth: 1.8)
                        
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
                        
                        scaledCtx.stroke(baseFrame, with: goldGradient, lineWidth: 1.5)
                        
                        // Curved Handle
                        var handlePath = Path()
                        handlePath.move(to: CGPoint(x: beakerRight - 1, y: beakerTop + 15))
                        handlePath.addCurve(to: CGPoint(x: beakerRight - 1, y: beakerBottom - 35),
                                            control1: CGPoint(x: beakerRight + 24, y: beakerTop + 10),
                                            control2: CGPoint(x: beakerRight + 24, y: beakerBottom - 30))
                        scaledCtx.stroke(handlePath, with: goldGradient, lineWidth: 2.0)
                        
                        // 5. LID DOME
                        var lidPath = Path()
                        lidPath.move(to: CGPoint(x: beakerLeft - 2, y: beakerTop))
                        lidPath.addLine(to: CGPoint(x: beakerRight + 2, y: beakerTop))
                        lidPath.addLine(to: CGPoint(x: beakerRight + 2, y: beakerTop - 4))
                        lidPath.addQuadCurve(to: CGPoint(x: beakerLeft - 2, y: beakerTop - 4), control: CGPoint(x: centerX, y: beakerTop - 15))
                        lidPath.closeSubpath()
                        
                        scaledCtx.fill(lidPath, with: .color(Color.primaryCopper.opacity(0.12)))
                        scaledCtx.stroke(lidPath, with: goldGradient, lineWidth: 1.5)
                        
                        // Silicone seal band
                        var sealPath = Path()
                        sealPath.move(to: CGPoint(x: beakerLeft - 1, y: beakerTop))
                        sealPath.addLine(to: CGPoint(x: beakerRight + 1, y: beakerTop))
                        scaledCtx.stroke(sealPath, with: .color(strokeColor.opacity(0.65)), lineWidth: 1.8)
                        
                        // 6. DYNAMIC PLUNGER SHAFT, KNOB & FILTER PLATE
                        // Plunger Shaft
                        var shaftPath = Path()
                        shaftPath.move(to: CGPoint(x: centerX, y: knobY + 5))
                        shaftPath.addLine(to: CGPoint(x: centerX, y: filterY))
                        scaledCtx.stroke(shaftPath, with: goldGradient, lineWidth: 1.8)
                        
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
                .frame(width: 196, height: 196)
            }
            .frame(width: 252, height: 252)
        }
    }
}

struct DummyTemplate {
    let name: String
    let currentPhase: String
    let timeText: String
    let subtitle: String
    let phases: [BrewPhase]
}

struct BrewPhase {
    let title: String
    let description: String
    let duration: String
    let icon: String
}

struct PhaseStackPickerView: View {
    let phases: [BrewPhase]
    let selectedIndex: Int
    
    var body: some View {
        ZStack {
            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                let layout = cardLayout(for: index)
                if layout.isVisible {
                    PhaseStackCard(phase: phase, isActive: index == selectedIndex)
                        .scaleEffect(layout.scale)
                        .offset(y: layout.offsetY)
                        .opacity(layout.opacity)
                        .blur(radius: layout.blur)
                        .zIndex(layout.zIndex)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .animation(.easeInOut(duration: 0.75), value: selectedIndex)
    }
    
    private func cardLayout(for index: Int) -> PhaseStackLayout {
        let delta = index - selectedIndex
        
        switch delta {
        case 0:
            return PhaseStackLayout(scale: 1.0, offsetY: 0, opacity: 1.0, blur: 0, zIndex: 3, isVisible: true)
        case -1:
            return PhaseStackLayout(scale: 0.90, offsetY: -32, opacity: 0.34, blur: 0, zIndex: 2, isVisible: true)
        case 1:
            return PhaseStackLayout(scale: 0.94, offsetY: 32, opacity: 0.44, blur: 0, zIndex: 1, isVisible: true)
        case -2:
            return PhaseStackLayout(scale: 0.84, offsetY: -48, opacity: 0.12, blur: 0.5, zIndex: 0, isVisible: true)
        case 2:
            return PhaseStackLayout(scale: 0.88, offsetY: 48, opacity: 0.16, blur: 0.5, zIndex: 0, isVisible: true)
        default:
            return PhaseStackLayout(scale: 0.82, offsetY: delta < 0 ? -64 : 64, opacity: 0, blur: 1, zIndex: -1, isVisible: false)
        }
    }
}

struct PhaseStackCard: View {
    let phase: BrewPhase
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isActive ? 0.08 : 0.04))
                    .frame(width: 34, height: 34)
                
                Image(systemName: phase.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? Color.primaryCopper : Color.white.opacity(0.45))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.title)
                    .font(.system(size: 15, weight: isActive ? .bold : .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.78))
                
                Text(phase.description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? Color.white.opacity(0.62) : Color.white.opacity(0.38))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 10)
            
            Text(phase.duration)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? Color.primaryCopper : Color.white.opacity(0.45))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 86)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(isActive ? 0.10 : 0.06))
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.17, green: 0.12, blue: 0.11).opacity(isActive ? 0.98 : 0.9),
                            Color(red: 0.12, green: 0.09, blue: 0.08).opacity(isActive ? 0.98 : 0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isActive ? Color.primaryCopper.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isActive ? Color.primaryCopper.opacity(0.12) : .clear, radius: 16, y: 8)
    }
}

private struct PhaseStackLayout {
    let scale: CGFloat
    let offsetY: CGFloat
    let opacity: Double
    let blur: CGFloat
    let zIndex: Double
    let isVisible: Bool
}
