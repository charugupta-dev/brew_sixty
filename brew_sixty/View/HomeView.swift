import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var activeIndex: Int = 0
    @State private var isZoomedOut = false
    @State private var selectedDose = "15g"
    @State private var showingTimer = false
    
    // 2 Dummy Templates (V60 & French Press)
    private let dummyCards = [
        DummyTemplate(
            name: "V60",
            imageName: "v60_brew_bg",
            currentPhase: "CURRENT: BLOOM",
            timeText: "00:45",
            subtitle: "45G BLOOM",
            phases: [
                BrewPhase(title: "Bloom", description: "45g Water • Swirl gently", duration: "45s", icon: "stopwatch"),
                BrewPhase(title: "First Pour", description: "To 150g • Spiral motion", duration: "60s", icon: "drop"),
                BrewPhase(title: "Final Drawdown", description: "To 250g • Flat bed", duration: "Ready", icon: "hourglass")
            ]
        ),
        DummyTemplate(
            name: "French Press",
            imageName: "french_press_bg",
            currentPhase: "CURRENT: STEEP",
            timeText: "04:00",
            subtitle: "STEEPING...",
            phases: [
                BrewPhase(title: "Steep", description: "Pour 320g • Let it sit", duration: "240s", icon: "stopwatch"),
                BrewPhase(title: "Plunge", description: "Press down slowly", duration: "15s", icon: "hourglass")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Solid dark charcoal background matching mock
            Color(red: 0.08, green: 0.08, blue: 0.08)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Serif Hello Charu! title
                    Text("Hello Charu!")
                        .font(.system(.largeTitle, design: .serif))
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    // Main rounded card container containing everything else
                    VStack(spacing: 20) {
                        // Wallpaper Carousel Switcher
                        TabView(selection: $activeIndex) {
                            ForEach(0..<dummyCards.count, id: \.self) { idx in
                                let card = dummyCards[idx]
                                ZStack {
                                    // Background Image Asset
                                    Image(card.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 300)
                                        .clipped()
                                        .cornerRadius(16)
                                        .overlay(Color.black.opacity(0.35)) // Dim overlay for text readability
                                    
                                    // Text Overlay exactly like mockup
                                    VStack(spacing: 12) {
                                        Text(card.currentPhase)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(Color.white.opacity(0.08)))
                                        
                                        Text(card.timeText)
                                            .font(.system(size: 64, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white)
                                        
                                        Text(card.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        
                                        Text(card.subtitle)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                .tag(idx)
                                .scaleEffect(isZoomedOut ? 0.85 : 1.0)
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
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: isZoomedOut ? 270 : 310)
                        
                        // Dose Selector pills
                        HStack(spacing: 12) {
                            doseButton("15g")
                            doseButton("18g")
                            doseButton("20g")
                        }
                        .padding(.top, 4)
                        
                        // Phases title
                        HStack {
                            Text("PHASES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1.0)
                                .foregroundStyle(Color.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // Phases lists
                        VStack(spacing: 12) {
                            let activeCard = dummyCards[activeIndex]
                            ForEach(activeCard.phases, id: \.title) { phase in
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.04))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: phase.icon)
                                            .font(.body)
                                            .foregroundStyle(Color.primaryCopper)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(phase.title)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.white)
                                        Text(phase.description)
                                            .font(.caption)
                                            .foregroundStyle(Color.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(phase.duration)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.primaryCopper)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.02)))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.04), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Start Brew button
                        Button {
                            showingTimer = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.subheadline)
                                Text("START BREW")
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
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.01))
                            .background(Color(red: 0.11, green: 0.10, blue: 0.09).opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingTimer) {
            Text("Timer running...")
        }
    }
    
    private func doseButton(_ label: String) -> some View {
        let isSelected = selectedDose == label
        return Button {
            selectedDose = label
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
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
  }

  struct DummyTemplate {
      let name: String
      let imageName: String
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
