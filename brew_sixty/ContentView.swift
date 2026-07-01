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
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab)
                        .tag(Tab.brew)
                        .tabItem {
                            Label("BREW", systemImage: "cup.and.saucer.fill")
                        }
                    
                    MethodsView(selectedTab: $selectedTab)
                        .tag(Tab.methods)
                        .tabItem {
                            Label("METHODS", systemImage: "square.grid.2x2.fill")
                        }
                    
                    JournalPlaceholderView()
                        .tag(Tab.journal)
                        .tabItem {
                            Label("JOURNAL", systemImage: "doc.text.fill")
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tint(Color.primaryCopper)
                .toolbarBackground(Color.black.opacity(0.92), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: BrewLog.self, inMemory: true)
}
