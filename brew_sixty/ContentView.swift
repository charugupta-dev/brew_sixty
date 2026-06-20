import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    @State private var selectedTab: Tab = .brews
    
    enum Tab {
        case brews
        case settings
    }
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchView(showLaunch: $showLaunchScreen)
                    .transition(.opacity)
            } else {
                ZStack(alignment: .bottom) {
                    // Active View
                    Group {
                        switch selectedTab {
                        case .brews:
                            HomeView()
                        case .settings:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Floating Capsule Tab Bar
                    HStack(spacing: 30) {
                        tabButton(tab: .brews, label: "Brews", systemImage: "cup.and.saucer.fill")
                        tabButton(tab: .settings, label: "Settings", systemImage: "gearshape.fill")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.4))
                            .background(.ultraThinMaterial, in: Capsule())
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func tabButton(tab: Tab, label: String, systemImage: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? Color.coffeeCream : Color.white.opacity(0.4))
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.coffeeAccent.opacity(0.35))
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
