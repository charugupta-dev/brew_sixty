import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let viewModel: BrewViewModel
    var onDismissAll: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Ambient Radial Gradient Background
            RadialGradient(
                colors: [Color(red: 0.18, green: 0.12, blue: 0.09), Color(red: 0.05, green: 0.04, blue: 0.03)],
                center: .top,
                startRadius: 10,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text(viewModel.isRunning ? "Brewing..." : "Ready to Brew")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TimelineView(.animation) { context in
                    let elapsed: TimeInterval = viewModel.calculateElapsed(from: context.date)
                    let progress: Double = viewModel.getProgress(for: elapsed)
                    
                    // Smooth transition from black to brown
                    let transitionDuration: TimeInterval = 0.8
                    let transitionProgress: Double = {
                        if elapsed < viewModel.bloomDuration {
                            return 0.0
                        } else {
                            return min((elapsed - viewModel.bloomDuration) / transitionDuration, 1.0)
                        }
                    }()
                    let coffeeBrown = Color(red: 0.43, green: 0.30, blue: 0.22)
                    let currentColor = interpolateColor(from: .black, to: coffeeBrown, fraction: transitionProgress)
                    
                    VStack(spacing: 30) {
                        ZStack {
                            Circle()
                                .stroke(.ultraThinMaterial, lineWidth: 16)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(currentColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            
                            // NATIVE SWIFTUI CANVAS FOR POURING ANIMATION
                            Canvas { ctx, size in
                                let time = context.date.timeIntervalSince1970
                                let w = size.width
                                let h = size.height
                                
                                // 1. DRAW CUP (Centered at bottom)
                                let cupW: CGFloat = 36
                                let cupH: CGFloat = 26
                                let cupX = (w - cupW) / 2
                                let cupY = h - cupH - 35
                                
                                // Cup Handle (Left side)
                                var handlePath = Path()
                                handlePath.addArc(
                                    center: CGPoint(x: cupX, y: cupY + cupH/2),
                                    radius: 6,
                                    startAngle: .degrees(90),
                                    endAngle: .degrees(270),
                                    clockwise: false
                                )
                                ctx.stroke(handlePath, with: .color(.white), lineWidth: 2)
                                
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
                                ctx.stroke(cupPath, with: .color(.white), lineWidth: 2)
                                
                                // Coffee Fill in Cup
                                let fillProgress = progress
                                if fillProgress > 0 {
                                    let fillH = (cupH - 4) * CGFloat(fillProgress)
                                    let fillY = (cupY + cupH - 2) - fillH
                                    var fillPath = Path()
                                    
                                    // Generate wavy surface using sin
                                    fillPath.move(to: CGPoint(x: cupX + 2, y: fillY))
                                    for x in Int(cupX + 2)...Int(cupX + cupW - 2) {
                                        let wave = sin(Double(x) * 0.4 + time * 8.0) * 1.5
                                        fillPath.addLine(to: CGPoint(x: CGFloat(x), y: fillY + CGFloat(wave)))
                                    }
                                    fillPath.addLine(to: CGPoint(x: cupX + cupW - 2, y: cupY + cupH - 2))
                                    fillPath.addLine(to: CGPoint(x: cupX + 2, y: cupY + cupH - 2))
                                    fillPath.closeSubpath()
                                    
                                    ctx.fill(fillPath, with: .color(Color(red: 0.31, green: 0.20, blue: 0.13)))
                                }
                                
                                // 2. DRAW KETTLE (Spout aligned to center vertically)
                                let kettleW: CGFloat = 40
                                let kettleH: CGFloat = 28
                                let kettleX = (w / 2) + 10
                                let kettleY: CGFloat = 30
                                
                                // Tilting animation transform
                                let tiltAngle = viewModel.isRunning ? sin(time * 1.5) * 6 - 8 : 0.0
                                
                                // Since GraphicsContext is a value type, copying it acts as save/restore state.
                                var kettleCtx = ctx
                                kettleCtx.translateBy(x: kettleX + kettleW/2, y: kettleY + kettleH/2)
                                kettleCtx.rotate(by: .degrees(tiltAngle))
                                kettleCtx.translateBy(x: -(kettleX + kettleW/2), y: -(kettleY + kettleH/2))
                                
                                // Kettle Body
                                var kettlePath = Path()
                                kettlePath.addRoundedRect(
                                    in: CGRect(x: kettleX, y: kettleY, width: kettleW, height: kettleH),
                                    cornerSize: CGSize(width: 4, height: 4)
                                )
                                kettleCtx.stroke(kettlePath, with: .color(.white), lineWidth: 2)
                                
                                // Spout (Left pointing spout)
                                var spoutPath = Path()
                                spoutPath.move(to: CGPoint(x: kettleX, y: kettleY + 12))
                                spoutPath.addLine(to: CGPoint(x: kettleX - 10, y: kettleY + 4))
                                spoutPath.addLine(to: CGPoint(x: kettleX - 10, y: kettleY + 8))
                                spoutPath.addLine(to: CGPoint(x: kettleX, y: kettleY + 18))
                                kettleCtx.stroke(spoutPath, with: .color(.white), lineWidth: 2)
                                
                                // Kettle Handle (Right side)
                                var kHandlePath = Path()
                                kHandlePath.addArc(
                                    center: CGPoint(x: kettleX + kettleW, y: kettleY + kettleH/2),
                                    radius: 6,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(90),
                                    clockwise: false
                                )
                                kettleCtx.stroke(kHandlePath, with: .color(.white), lineWidth: 2)
                                
                                // 3. DRAW DROPLET STREAM (Pours from spout center vertically down to cup)
                                if viewModel.isRunning {
                                    // Spout tip relative position
                                    let spoutTipX = kettleX - 10
                                    let spoutTipY = kettleY + 6
                                    
                                    // Spout tip coordinates taking tilt into account
                                    let angleRad = tiltAngle * .pi / 180.0
                                    let originX = kettleX + kettleW/2
                                    let originY = kettleY + kettleH/2
                                    
                                    // Convert to CGFloats to avoid type mismatch errors
                                    let cosAngle = CGFloat(cos(angleRad))
                                    let sinAngle = CGFloat(sin(angleRad))
                                    let rotatedSpoutX = originX + (spoutTipX - originX) * cosAngle - (spoutTipY - originY) * sinAngle
                                    let rotatedSpoutY = originY + (spoutTipX - originX) * sinAngle + (spoutTipY - originY) * cosAngle
                                    
                                    // Target coordinate based on rotated spout tip
                                    let targetX = rotatedSpoutX
                                    let startY = rotatedSpoutY
                                    let endY = cupY
                                    
                                    // Draw falling particles / droplets
                                    let dropletCount = 4
                                    let speed: Double = 4.0
                                    for i in 0..<dropletCount {
                                        let offset = Double(i) / Double(dropletCount)
                                        let progress = (time * speed + offset).truncatingRemainder(dividingBy: 1.0)
                                        let dropY = startY + (endY - startY) * CGFloat(progress)
                                        
                                        // Draw small circular coffee droplets
                                        var dropPath = Path()
                                        dropPath.addArc(
                                            center: CGPoint(x: targetX, y: dropY),
                                            radius: 2,
                                            startAngle: .degrees(0),
                                            endAngle: .degrees(360),
                                            clockwise: false
                                        )
                                        ctx.fill(dropPath, with: .color(coffeeBrown))
                                    }
                                }
                            }
                            .frame(width: 200, height: 200)
                        }
                        .frame(width: 320, height: 320)
                        
                        // Timer Readout & Subtitle Below the Circle
                        VStack(spacing: 8) {
                            Text(formatTime(elapsed))
                                .font(.system(size: 72, weight: .light, design: .rounded))
                                .contentTransition(.numericText(value: elapsed))
                                .foregroundStyle(.white)
                            
                            Text(viewModel.getPhaseText(for: elapsed))
                                .font(.headline)
                                .foregroundStyle(Color.coffeeCream)
                        }
                    }
                }
                
                HStack(spacing: 40) {
                    Button {
                        if let onDismissAll = onDismissAll {
                            onDismissAll()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.primary)
                            .frame(width: 80, height: 80)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button {
                        if viewModel.isRunning {
                            viewModel.toggleTimer()
                            viewModel.saveLog(in: modelContext)
                            if let onDismissAll = onDismissAll {
                                onDismissAll()
                            } else {
                                dismiss()
                            }
                        } else {
                            viewModel.toggleTimer()
                        }
                    } label: {
                        Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.background)
                            .frame(width: 80, height: 80)
                            .background(Color.primary, in: Circle())
                            .shadow(color: .primary.opacity(0.3), radius: 10, y: 5)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !viewModel.isRunning {
                viewModel.toggleTimer()
            }
        }
        .onChange(of: viewModel.isFinished) { oldValue, newValue in
            if newValue == true {
                viewModel.saveLog(in: modelContext)
                if let onDismissAll = onDismissAll {
                    onDismissAll()
                } else {
                    dismiss()
                }
            }
        }
    }
    
    private func interpolateColor(from start: Color, to end: Color, fraction: Double) -> Color {
        let f = min(max(fraction, 0), 1)
        #if canImport(UIKit)
        let uiStart = UIColor(start)
        let uiEnd = UIColor(end)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 1
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 1
        
        if let rgbStart = uiStart.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
           let comps = rgbStart.components, comps.count >= 3 {
            r1 = comps[0]
            g1 = comps[1]
            b1 = comps[2]
            a1 = comps.count > 3 ? comps[3] : 1.0
        } else {
            uiStart.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        }
        
        if let rgbEnd = uiEnd.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
           let comps = rgbEnd.components, comps.count >= 3 {
            r2 = comps[0]
            g2 = comps[1]
            b2 = comps[2]
            a2 = comps.count > 3 ? comps[3] : 1.0
        } else {
            uiEnd.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        }
        
        return Color(red: Double(r1 + (r2 - r1) * CGFloat(f)),
                     green: Double(g1 + (g2 - g1) * CGFloat(f)),
                     blue: Double(b1 + (b2 - b1) * CGFloat(f)),
                     opacity: Double(a1 + (a2 - a1) * CGFloat(f)))
        #else
        return end
        #endif
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    TimerView(viewModel: BrewViewModel(beanWeight: 8, ratio: 1.12))
}
