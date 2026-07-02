import SwiftUI

struct BrewPhase {
    let title: String
    let description: String
    let duration: String
    let icon: String
    var waterAmount: String? = nil
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
        .frame(height: 64)
        .clipped()
        .animation(.easeInOut(duration: 0.6), value: selectedIndex)
    }
    
    private func cardLayout(for index: Int) -> PhaseStackLayout {
        let delta = index - selectedIndex
        
        switch delta {
        case 0:
            return PhaseStackLayout(scale: 1.0, offsetY: 0, opacity: 1.0, blur: 0, zIndex: 3, isVisible: true)
        case -1:
            return PhaseStackLayout(scale: 0.95, offsetY: -40, opacity: 0.0, blur: 0, zIndex: 2, isVisible: true)
        case 1:
            return PhaseStackLayout(scale: 0.95, offsetY: 40, opacity: 0.0, blur: 0, zIndex: 1, isVisible: true)
        default:
            return PhaseStackLayout(scale: 0.9, offsetY: delta < 0 ? -60 : 60, opacity: 0, blur: 0, zIndex: -1, isVisible: false)
        }
    }
}

struct PhaseStackCard: View {
    let phase: BrewPhase
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(phase.title)
                    .font(.system(size: 15, weight: isActive ? .bold : .semibold))
                    .foregroundStyle(isActive ? Color.coffeeCream : Color.coffeeCream.opacity(0.78))
                
                if let water = phase.waterAmount {
                    Text("— \(water)")
                        .font(.system(size: 15, weight: isActive ? .bold : .semibold))
                        .foregroundStyle(isActive ? Color.primaryCopper : Color.primaryCopper.opacity(0.7))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            
            Spacer(minLength: 10)
            
            if phase.duration != "Ready" {
                Text(phase.duration)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isActive ? Color.primaryCopper : Color.coffeeCream.opacity(0.45))
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.coffeeCream.opacity(isActive ? 0.10 : 0.06))
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
                .stroke(isActive ? Color.primaryCopper.opacity(0.4) : Color.coffeeCream.opacity(0.08), lineWidth: 1)
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
