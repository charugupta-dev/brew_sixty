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
    let phaseProgress: Double

    private var safeSelectedIndex: Int {
        guard !phases.isEmpty else { return 0 }
        return min(max(selectedIndex, 0), phases.count - 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, _ in
                    HStack(spacing: 0) {
                        phaseMarker(for: index)

                        if index < phases.count - 1 {
                            phaseConnector(for: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)

            if !phases.isEmpty {
                Text(phases[safeSelectedIndex].title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.coffeeCream.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .contentTransition(.opacity)
                    .id(phases[safeSelectedIndex].title)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selectedIndex)
        .animation(.linear(duration: 0.12), value: phaseProgress)
    }

    @ViewBuilder
    private func phaseMarker(for index: Int) -> some View {
        let isActive = index == safeSelectedIndex
        let isCompleted = index < safeSelectedIndex

        Capsule(style: .continuous)
            .fill(markerColor(isActive: isActive, isCompleted: isCompleted))
            .frame(width: isActive ? 24 : 8, height: 8)
            .overlay {
                if isActive {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
                }
            }
            .shadow(color: isActive ? Color.primaryCopper.opacity(0.18) : .clear, radius: 8, y: 2)
    }

    private func markerColor(isActive: Bool, isCompleted: Bool) -> Color {
        if isActive {
            return Color.primaryCopper
        }

        if isCompleted {
            return Color.primaryCopper.opacity(0.42)
        }

        return Color(red: 0.86, green: 0.84, blue: 0.81)
    }

    private func connectorColor(for index: Int) -> Color {
        index < safeSelectedIndex ? Color.primaryCopper.opacity(0.30) : Color(red: 0.86, green: 0.84, blue: 0.81)
    }

    @ViewBuilder
    private func phaseConnector(for index: Int) -> some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 0)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(connectorColor(for: index))
                    .frame(height: 1)

                if currentConnectorFillWidth(for: index, totalWidth: width) > 0 {
                    Rectangle()
                        .fill(Color.primaryCopper.opacity(0.72))
                        .frame(width: currentConnectorFillWidth(for: index, totalWidth: width), height: 1.5)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 8)
        .padding(.horizontal, 6)
    }

    private func currentConnectorFillWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < safeSelectedIndex {
            return totalWidth
        }

        if index == safeSelectedIndex && safeSelectedIndex < phases.count - 1 {
            return totalWidth * CGFloat(min(max(phaseProgress, 0), 1))
        }

        return 0
    }
}
