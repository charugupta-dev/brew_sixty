import SwiftUI

struct SmokeParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var scale: CGFloat
    var maxScale: CGFloat
    var opacity: Double
    var color: Color
    var lifetime: Double
    var maxLifetime: Double
}

struct EmberParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var opacity: Double
    var color: Color
    var lifetime: Double
    var maxLifetime: Double
}

class SmokeParticleSystem {
    var particles: [SmokeParticle] = []
    var embers: [EmberParticle] = []
    var lastTime = Date()
    
    func update(now: Date, bounds: CGSize) {
        let dt = now.timeIntervalSince(lastTime)
        lastTime = now
        guard dt > 0 else { return }
        
        // 1. Update smoke particles
        var updatedParticles: [SmokeParticle] = []
        for var p in particles {
            p.lifetime -= dt
            if p.lifetime > 0 {
                p.x += p.vx * dt
                p.y += p.vy * dt
                
                // Slow down when rising past 60% of screen height
                let verticalRatio = p.y / bounds.height
                if verticalRatio < 0.6 {
                    let targetVy: CGFloat = -22.0
                    p.vy = p.vy + (targetVy - p.vy) * CGFloat(dt) * 1.5
                }
                
                // Add soft wave motion
                p.x += sin(p.y * 0.01 + CGFloat(p.vx)) * 0.3
                
                // Scale up over time
                let progress = 1.0 - (p.lifetime / p.maxLifetime)
                p.scale = p.scale + (p.maxScale - p.scale) * CGFloat(dt) * 0.4
                
                // Fade in and then fade out
                if progress < 0.3 {
                    p.opacity = Double(progress / 0.3) * 0.28
                } else {
                    p.opacity = Double(1.0 - progress) * 0.28
                }
                
                updatedParticles.append(p)
            }
        }
        particles = updatedParticles
        
        // 2. Update embers
        var updatedEmbers: [EmberParticle] = []
        for var e in embers {
            e.lifetime -= dt
            if e.lifetime > 0 {
                e.x += e.vx * dt
                e.y += e.vy * dt
                
                // Slow down when rising past 60% of screen height
                let verticalRatio = e.y / bounds.height
                if verticalRatio < 0.6 {
                    let targetVy: CGFloat = -25.0
                    e.vy = e.vy + (targetVy - e.vy) * CGFloat(dt) * 1.5
                }
                
                // Slight wind sway
                e.x += sin(e.y * 0.02) * 0.4
                
                let progress = 1.0 - (e.lifetime / e.maxLifetime)
                e.opacity = Double(1.0 - progress) * 1.0
                
                updatedEmbers.append(e)
            }
        }
        embers = updatedEmbers
        
        // Spawn smoke particles
        if particles.count < 55 && Double.random(in: 0...1) < 0.22 {
            let maxLifetime = Double.random(in: 8.0...12.0)
            let color = Double.random(in: 0...1) < 0.55 ? 
                Color(red: 0.28, green: 0.38, blue: 0.45) : // Steel blue smoke
                Color(red: 0.72, green: 0.42, blue: 0.28)   // Warm copper smoke
                
            let p = SmokeParticle(
                x: bounds.width / 2 + CGFloat.random(in: -70...70),
                y: bounds.height + 60,
                vx: CGFloat.random(in: -35...35), // Spread smoke horizontally
                vy: CGFloat.random(in: -120 ... -80),
                scale: CGFloat.random(in: 45...80),
                maxScale: CGFloat.random(in: 260...380),
                opacity: 0,
                color: color,
                lifetime: maxLifetime,
                maxLifetime: maxLifetime
            )
            particles.append(p)
        }
        
        // Spawn embers (dots) with wider spread velocity
        if embers.count < 85 && Double.random(in: 0...1) < 0.45 {
            let maxLifetime = Double.random(in: 4.0...7.0)
            let e = EmberParticle(
                x: bounds.width / 2 + CGFloat.random(in: -30...30), // Spawn close to center bottom
                y: bounds.height + 10,
                vx: CGFloat.random(in: -45...45), // Wider horizontal velocity spreads them fanning outwards
                vy: CGFloat.random(in: -120 ... -70),
                size: CGFloat.random(in: 2.0...5.5), // Larger and more visible
                opacity: 1.0,
                color: Color(red: 1.0, green: 0.72, blue: 0.38), // Glowing bright copper
                lifetime: maxLifetime,
                maxLifetime: maxLifetime
            )
            embers.append(e)
        }
    }
}

struct SmokeStaticBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05)
            
            Image("timer_card_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.85)
        }
        .ignoresSafeArea()
    }
}

struct SmokeParticleOverlay: View {
    @State private var system = SmokeParticleSystem()
    
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
}
