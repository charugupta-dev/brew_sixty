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
                        .fill(Color.white.opacity(0.01))
                        .background(Color(red: 0.10, green: 0.09, blue: 0.09).opacity(0.6))
                )
                .liquidGlassBorder(cornerRadius: 16)
                
                // Dose Selection pills
                HStack(spacing: 10) {
                    doseButton("8g")
                    doseButton("16g")
                    doseButton("24g")
                }
                .padding(.top, 2)
                
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
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.01))
                .background(Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.5))
        )
        .liquidGlassBorder(cornerRadius: 24)
    }
    
    private func doseButton(_ label: String) -> some View {
        let doseNum = Double(label.replacingOccurrences(of: "g", with: "")) ?? 15.0
        let isSelected = abs(viewModel.beanWeight - doseNum) < 0.1
        
        return Button {
            viewModel.beanWeight = doseNum
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
                        
                        let w: CGFloat = 200
                        let h: CGFloat = 200
                        
                        // 1. DRAW CUP (Centered at bottom)
                        let cupW: CGFloat = 36
                        let cupH: CGFloat = 26
                        let cupX = (w - cupW) / 2
                        let cupY = h - cupH - 35
                        
                        // Cup Handle
                        var handlePath = Path()
                        handlePath.addArc(
                            center: CGPoint(x: cupX, y: cupY + cupH/2),
                            radius: 6,
                            startAngle: .degrees(90),
                            endAngle: .degrees(270),
                            clockwise: false
                        )
                        scaledCtx.stroke(handlePath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Cup Body
                        var cupPath = Path()
                        cupPath.move(to: CGPoint(x: cupX, y: cupY))
                        cupPath.addLine(to: CGPoint(x: cupX, y: cupY + cupH - 8))
                        cupPath.addQuadCurve(
                            to: CGPoint(x: cupX + 8, y: cupY + cupH),
                            control: CGPoint(x: cupX, y: cupY + cupH)
                        )
                        cupPath.addLine(to: CGPoint(x: cupX + cupW - 8, y: cupY + cupH))
                        cupPath.addQuadCurve(
                            to: CGPoint(x: cupX + cupW, y: cupY + cupH - 8),
                            control: CGPoint(x: cupX + cupW, y: cupY + cupH)
                        )
                        cupPath.addLine(to: CGPoint(x: cupX + cupW, y: cupY))
                        scaledCtx.stroke(cupPath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Coffee Fill
                        if progress > 0 {
                            let fillH = (cupH - 4) * CGFloat(progress)
                            let fillY = (cupY + cupH - 2) - fillH
                            var fillPath = Path()
                            
                            fillPath.move(to: CGPoint(x: cupX + 2, y: fillY))
                            for x in Int(cupX + 2)...Int(cupX + cupW - 2) {
                                let wave = sin(Double(x) * 0.4 + time * 8.0) * 1.5
                                fillPath.addLine(to: CGPoint(x: CGFloat(x), y: fillY + CGFloat(wave)))
                            }
                            fillPath.addLine(to: CGPoint(x: cupX + cupW - 2, y: cupY + cupH - 2))
                            fillPath.addLine(to: CGPoint(x: cupX + 2, y: cupY + cupH - 2))
                            fillPath.closeSubpath()
                            
                            scaledCtx.fill(fillPath, with: .color(fillColor))
                        }
                        
                        // 2. DRAW KETTLE
                        let kettleW: CGFloat = 40
                        let kettleH: CGFloat = 28
                        let kettleX = (w / 2) + 10
                        let kettleY: CGFloat = 30
                        let tiltAngle = viewModel.isRunning ? sin(time * 1.5) * 6 - 8 : 0.0
                        
                        var kettleCtx = scaledCtx
                        kettleCtx.translateBy(x: kettleX + kettleW/2, y: kettleY + kettleH/2)
                        kettleCtx.rotate(by: .degrees(tiltAngle))
                        kettleCtx.translateBy(x: -(kettleX + kettleW/2), y: -(kettleY + kettleH/2))
                        
                        var kettlePath = Path()
                        kettlePath.addRoundedRect(
                            in: CGRect(x: kettleX, y: kettleY, width: kettleW, height: kettleH),
                            cornerSize: CGSize(width: 4, height: 4)
                        )
                        kettleCtx.stroke(kettlePath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Spout
                        var spoutPath = Path()
                        spoutPath.move(to: CGPoint(x: kettleX, y: kettleY + 12))
                        spoutPath.addLine(to: CGPoint(x: kettleX - 10, y: kettleY + 4))
                        spoutPath.addLine(to: CGPoint(x: kettleX - 10, y: kettleY + 8))
                        spoutPath.addLine(to: CGPoint(x: kettleX, y: kettleY + 18))
                        kettleCtx.stroke(spoutPath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Handle
                        var kHandlePath = Path()
                        kHandlePath.addArc(
                            center: CGPoint(x: kettleX + kettleW, y: kettleY + kettleH/2),
                            radius: 6,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(90),
                            clockwise: false
                        )
                        kettleCtx.stroke(kHandlePath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // 3. DROPLETS
                        if viewModel.isRunning {
                            let spoutTipX = kettleX - 10
                            let spoutTipY = kettleY + 6
                            let angleRad = tiltAngle * .pi / 180.0
                            let originX = kettleX + kettleW/2
                            let originY = kettleY + kettleH/2
                            
                            let cosAngle = CGFloat(cos(angleRad))
                            let sinAngle = CGFloat(sin(angleRad))
                            let rotatedSpoutX = originX + (spoutTipX - originX) * cosAngle - (spoutTipY - originY) * sinAngle
                            let rotatedSpoutY = originY + (spoutTipX - originX) * sinAngle + (spoutTipY - originY) * cosAngle
                            
                            let targetX = rotatedSpoutX
                            let startY = rotatedSpoutY
                            let endY = cupY
                            
                            let dropletCount = 4
                            let speed: Double = 4.0
                            for i in 0..<dropletCount {
                                let offset = Double(i) / Double(dropletCount)
                                let progress = (time * speed + offset).truncatingRemainder(dividingBy: 1.0)
                                let dropY = startY + (endY - startY) * CGFloat(progress)
                                
                                var dropPath = Path()
                                dropPath.addArc(
                                    center: CGPoint(x: targetX, y: dropY),
                                    radius: 2,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360),
                                    clockwise: false
                                )
                                scaledCtx.fill(dropPath, with: .color(accentColor))
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
                        
                        // Beaker coordinates
                        let pressW: CGFloat = 60
                        let pressH: CGFloat = 90
                        let pressX = (w - pressW) / 2
                        let pressY = (h - pressH) / 2 + 10
                        
                        // Draw Beaker
                        var pressPath = Path()
                        pressPath.move(to: CGPoint(x: pressX, y: pressY))
                        pressPath.addLine(to: CGPoint(x: pressX, y: pressY + pressH))
                        pressPath.addLine(to: CGPoint(x: pressX + pressW, y: pressY + pressH))
                        pressPath.addLine(to: CGPoint(x: pressX + pressW, y: pressY))
                        scaledCtx.stroke(pressPath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Handle
                        var handlePath = Path()
                        handlePath.move(to: CGPoint(x: pressX + pressW, y: pressY + 20))
                        handlePath.addLine(to: CGPoint(x: pressX + pressW + 12, y: pressY + 20))
                        handlePath.addLine(to: CGPoint(x: pressX + pressW + 12, y: pressY + pressH - 20))
                        handlePath.addLine(to: CGPoint(x: pressX + pressW, y: pressY + pressH - 20))
                        scaledCtx.stroke(handlePath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Coffee Fill
                        let coffeeFillH = pressH - 16
                        let coffeeFillY = pressY + pressH - coffeeFillH
                        var coffeePath = Path()
                        coffeePath.addRect(CGRect(x: pressX + 2, y: coffeeFillY, width: pressW - 4, height: coffeeFillH - 2))
                        scaledCtx.fill(coffeePath, with: .color(fillColor))
                        
                        // Plunger plate
                        let fpSteepDuration: TimeInterval = 240.0
                        let fpPlungeDuration: TimeInterval = 15.0
                        let steepProgress: Double = {
                            if viewModel.elapsed < fpSteepDuration {
                                return 0.0
                            } else {
                                return min((viewModel.elapsed - fpSteepDuration) / fpPlungeDuration, 1.0)
                            }
                        }()
                        
                        let plungerStart = coffeeFillY
                        let plungerEnd = pressY + pressH - 10
                        let plungerY = plungerStart + (plungerEnd - plungerStart) * CGFloat(steepProgress)
                        
                        // Plunger stem
                        var stemPath = Path()
                        stemPath.move(to: CGPoint(x: w/2, y: pressY - 15))
                        stemPath.addLine(to: CGPoint(x: w/2, y: plungerY))
                        scaledCtx.stroke(stemPath, with: .color(strokeColor), lineWidth: strokeWidth)
                        
                        // Knob
                        var knobPath = Path()
                        knobPath.addArc(center: CGPoint(x: w/2, y: pressY - 15), radius: 5, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
                        scaledCtx.fill(knobPath, with: .color(strokeColor))
                        
                        // Plate
                        var platePath = Path()
                        platePath.move(to: CGPoint(x: pressX + 3, y: plungerY))
                        platePath.addLine(to: CGPoint(x: pressX + pressW - 3, y: plungerY))
                        scaledCtx.stroke(platePath, with: .color(accentColor), lineWidth: strokeWidth + 0.5)
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
        .frame(height: 178)
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
