import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showLaunchScreen = true
    @State private var selectedTab: Tab = .brew
    
    enum Tab {
        case brew
        case methods
        case journal
    }
    
    var body: some View {
        ZStack {
            if showLaunchScreen {
                LaunchView(showLaunch: $showLaunchScreen)
                    .transition(.opacity)
            } else {
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tag(Tab.brew)
                            .toolbar(.hidden, for: .tabBar)
                        
                        MethodsPlaceholderView()
                            .tag(Tab.methods)
                            .toolbar(.hidden, for: .tabBar)
                        
                        JournalPlaceholderView()
                            .tag(Tab.journal)
                            .toolbar(.hidden, for: .tabBar)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom Tab Bar matching the mock (Brew, Methods, Journal)
                    HStack(spacing: 40) {
                        tabButton(tab: .brew, label: "BREW", systemImage: "cup.and.saucer.fill")
                        tabButton(tab: .methods, label: "METHODS", systemImage: "square.grid.2x2.fill")
                        tabButton(tab: .journal, label: "JOURNAL", systemImage: "doc.text.fill")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
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
                    .font(.body)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.primaryCopper : Color.white.opacity(0.4))
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.primaryCopper.opacity(0.15))
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

